import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bitstream/bit_utils.dart';
import '../channel/channel_id.dart';
import '../channel/channel_registry_provider.dart';
import '../compression/codec_registry_provider.dart';
import '../crypto/cipher_registry_provider.dart';
import '../protocol/metadata_envelope.dart';
import '../protocol/metadata_payload.dart';
import '../protocol/packet.dart';
import '../protocol/packet_header.dart';
import '../protocol/packet_stream_parser.dart';
import '../protocol/packet_type.dart';
import '../protocol/protocol_constants.dart';
import '../security/security_config.dart';
import 'file_chunker.dart';
import 'file_reassembler.dart';
import 'sha256_verifier.dart';
import 'transfer_id.dart';
import 'transfer_report.dart';
import 'transfer_state.dart';
import 'transfer_statistics.dart';

const _kInterPacketGap = Duration(milliseconds: 250);

const _kReceiveIdleTimeout = Duration(seconds: 8);
const _kMaxSanePacketCount = 1000000;

class TransferManagerState {
  const TransferManagerState({required this.phase, required this.statistics, this.report});

  final TransferPhase phase;
  final TransferStatistics statistics;
  final TransferReport? report;

  static TransferManagerState initial() =>
      TransferManagerState(phase: const TransferIdle(), statistics: TransferStatistics());

  TransferManagerState copyWith({
    TransferPhase? phase,
    TransferStatistics? statistics,
    TransferReport? report,
  }) {
    return TransferManagerState(
      phase: phase ?? this.phase,
      statistics: statistics ?? this.statistics,
      report: report ?? this.report,
    );
  }
}

class TransferManager extends Notifier<TransferManagerState> {
  @override
  TransferManagerState build() => TransferManagerState.initial();

  ChannelId? _activeChannelId;
  bool _cancelRequested = false;
  Timer? _idleTimer;
  Completer<void>? _receiveStopCompleter;

  Future<void> startTransmit({
    required ChannelId channelId,
    required File file,
    required SecurityConfig security,
  }) async {
    debugPrint('[TransferManager] startTransmit() channel=${channelId.name} file=${file.path}');
    _activeChannelId = channelId;
    _cancelRequested = false;
    final channel = ref.read(channelRegistryProvider).forId(channelId);
    final cipher = ref.read(cipherRegistryProvider).forId(security.cipherId);
    final codec = ref.read(codecRegistryProvider).forId(security.codecId);
    final key = security.derivedKey;

    state = TransferManagerState.initial().copyWith(phase: const TransferCalibrating());
    debugPrint('[TransferManager] calibrating ${channelId.name}...');
    try {
      await channel.calibrate();
      debugPrint('[TransferManager] calibration OK');
    } catch (e) {
      debugPrint('[TransferManager] ERROR: calibration failed: $e');
      state = state.copyWith(phase: TransferFailed('Calibration failed: $e'));
      _activeChannelId = null;
      return;
    }

    try {
      final originalBytes = await file.readAsBytes();
      debugPrint('[TransferManager] read ${originalBytes.length} byte(s) from disk');
      final originalSha256 = sha256Hex(originalBytes);
      final compressed = codec.encode(originalBytes);
      final nonceForData = MetadataEnvelope.generateNonce(cipher.nonceLength);
      final cipherText = await cipher.encrypt(compressed, key: key, nonce: nonceForData);
      final chunkResult = FileChunker.chunkBytes(
        cipherText,
        sha256Hex: originalSha256,
        totalBytes: originalBytes.length,
      );
      final transferId = generateTransferId();
      debugPrint('[TransferManager] transferId=$transferId, ${chunkResult.chunks.length} chunk(s), '
          'compressed=${compressed.length}B, cipherText=${cipherText.length}B');
      final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'file.bin';
      final metadata = MetadataPayload(
        fileName: fileName,
        fileSizeBytes: chunkResult.totalBytes,
        mimeType: 'application/octet-stream',
        totalPacketCount: chunkResult.chunks.length,
        sha256Hex: chunkResult.sha256Hex,
      );
      final metadataBytes = await MetadataEnvelope.encode(
        metadata,
        cipher: cipher,
        key: key,
        nonceForData: nonceForData,
      );
      final metadataPacket = Packet(
        header: PacketHeader(
          type: PacketType.metadata,
          transferId: transferId,
          sequence: 0,
          payloadLength: metadataBytes.length,
        ),
        payload: metadataBytes,
      );

      state = state.copyWith(phase: const TransferTransmitting(0.0));

      final metadataBits = BitUtils.bytesToBits(metadataPacket.toBytes());
      final totalChunks = chunkResult.chunks.length;
      final totalBits = metadataBits.length * ProtocolConstants.metadataRepeatCount +
          chunkResult.chunks.fold<int>(0, (sum, chunk) => sum + Packet.totalBytesFor(chunk.length) * 8);
      var sentBits = 0;

      debugPrint('[TransferManager] transmitting metadata packet '
          '(x${ProtocolConstants.metadataRepeatCount} repeats)');
      for (var i = 0; i < ProtocolConstants.metadataRepeatCount; i++) {
        await channel.startTransmit(metadataBits, config: const {});
        sentBits += metadataBits.length;
        state = state.copyWith(phase: TransferTransmitting(sentBits / totalBits));
        await Future.delayed(_kInterPacketGap);
      }

      var stats = state.statistics;
      for (var i = 0; i < totalChunks; i++) {
        final chunk = chunkResult.chunks[i];
        final packet = Packet(
          header: PacketHeader(
            type: PacketType.data,
            transferId: transferId,
            sequence: i + 1,
            payloadLength: chunk.length,
          ),
          payload: chunk,
        );
        final packetBits = BitUtils.bytesToBits(packet.toBytes());
        debugPrint('[TransferManager] transmitting data packet ${i + 1}/$totalChunks '
            '(${chunk.length}B payload)');
        await channel.startTransmit(packetBits, config: const {});
        sentBits += packetBits.length;
        await Future.delayed(_kInterPacketGap);

        stats = stats.copyWith(
          packetsSent: stats.packetsSent + 1,
          bytesTransferred: stats.bytesTransferred + chunk.length,
        );
        state = state.copyWith(statistics: stats, phase: TransferTransmitting(sentBits / totalBits));
      }

      final report = TransferReport(
        channel: channelId,
        fileName: metadata.fileName,
        sizeBytes: metadata.fileSizeBytes,
        duration: stats.elapsed,
        averageRateBytesPerSec: stats.rateBytesPerSec,
        packetsSent: stats.packetsSent,
        packetsReceived: 0,
        packetErrors: 0,
        verified: null,
      );
      debugPrint('[TransferManager] startTransmit() COMPLETE: ${stats.packetsSent} packet(s), '
          '${stats.bytesTransferred} byte(s) in ${stats.elapsed}');
      state = state.copyWith(phase: const TransferComplete(), report: report);
    } catch (e) {
      debugPrint('[TransferManager] ERROR: transmission failed: $e');
      state = state.copyWith(
        phase: _cancelRequested ? const TransferIdle() : TransferFailed('Transmission failed: $e'),
      );
    } finally {
      _cancelRequested = false;
      _activeChannelId = null;
      await channel.stop();
      debugPrint('[TransferManager] startTransmit() channel stopped');
    }
  }

  Future<void> startReceiveFile({
    required ChannelId channelId,
    required Directory saveDirectory,
    required SecurityConfig security,
  }) async {
    debugPrint('[TransferManager] startReceiveFile() channel=${channelId.name} '
        'saveDir=${saveDirectory.path}');
    _activeChannelId = channelId;
    _cancelRequested = false;
    final channel = ref.read(channelRegistryProvider).forId(channelId);
    final cipher = ref.read(cipherRegistryProvider).forId(security.cipherId);
    final codec = ref.read(codecRegistryProvider).forId(security.codecId);
    final key = security.derivedKey;

    state = TransferManagerState.initial().copyWith(phase: const TransferCalibrating());
    debugPrint('[TransferManager] calibrating ${channelId.name}...');
    try {
      await channel.calibrate();
      debugPrint('[TransferManager] calibration OK');
    } catch (e) {
      debugPrint('[TransferManager] ERROR: calibration failed: $e');
      state = state.copyWith(phase: TransferFailed('Calibration failed: $e'));
      _activeChannelId = null;
      return;
    }

    debugPrint('[TransferManager] listening for signal...');
    state = state.copyWith(phase: const TransferReceiving(0.0));

    final parser = PacketStreamParser();
    MetadataPayload? metadata;
    FileReassembler? reassembler;
    Uint8List? nonceForData;
    String? metadataFailureReason;
    var stats = state.statistics;
    final stopCompleter = Completer<void>();
    _receiveStopCompleter = stopCompleter;

    void resetIdleTimer() {
      _idleTimer?.cancel();
      _idleTimer = Timer(_kReceiveIdleTimeout, () {
        if (!stopCompleter.isCompleted) stopCompleter.complete();
      });
    }

    final parseSubscription = parser.events.listen((event) async {
      resetIdleTimer();
      switch (event) {
        case PacketParsedEvent(:final packet):
          if (packet.header.type == PacketType.metadata) {
            if (metadata == null && metadataFailureReason == null) {
              debugPrint('[TransferManager] metadata packet received, decoding...');
              try {
                final result = await MetadataEnvelope.decode(packet.payload, cipher: cipher, key: key);
                if (result.payload.totalPacketCount <= 0 ||
                    result.payload.totalPacketCount > _kMaxSanePacketCount) {
                  throw const FormatException('Implausible packet count');
                }
                metadata = result.payload;
                nonceForData = result.nonceForData;
                reassembler = FileReassembler(totalPacketCount: metadata!.totalPacketCount);
                debugPrint('[TransferManager] metadata OK: ${metadata!.fileName}, '
                    '${metadata!.totalPacketCount} packet(s) expected');
              } catch (e) {
                debugPrint('[TransferManager] ERROR: metadata decode failed: $e');
                metadataFailureReason = 'Metadata decode failed - check passphrase/cipher/codec match';
                if (!stopCompleter.isCompleted) stopCompleter.complete();
              }
            }
          } else if (reassembler != null) {
            reassembler!.addChunk(packet.header.sequence, packet.payload);
            stats = stats.copyWith(
              packetsReceived: stats.packetsReceived + 1,
              bytesTransferred: stats.bytesTransferred + packet.payload.length,
            );
            debugPrint('[TransferManager] data packet seq=${packet.header.sequence} received '
                '(${reassembler!.receivedPacketCount}/${metadata!.totalPacketCount})');
            final progress = reassembler!.receivedPacketCount / metadata!.totalPacketCount;
            state = state.copyWith(statistics: stats, phase: TransferReceiving(progress));
            if (reassembler!.isComplete && !stopCompleter.isCompleted) {
              debugPrint('[TransferManager] all packets received, stopping receive loop');
              stopCompleter.complete();
            }
          }
        case PacketCrcErrorEvent():
          debugPrint('[TransferManager] CRC error (total=${stats.crcErrors + 1})');
          stats = stats.copyWith(crcErrors: stats.crcErrors + 1, resyncCount: stats.resyncCount + 1);
          state = state.copyWith(statistics: stats);
      }
    });

    final symbolSubscription = channel.startReceive(config: const {}).listen((symbol) {
      resetIdleTimer();
      parser.addBits([symbol.bit]);
    });

    resetIdleTimer();
    await stopCompleter.future;
    debugPrint('[TransferManager] receive loop stopped');
    _idleTimer?.cancel();
    _receiveStopCompleter = null;

    await channel.stop();
    await symbolSubscription.cancel();
    await parseSubscription.cancel();
    await parser.dispose();

    if (metadataFailureReason != null) {
      state = state.copyWith(
        phase: _cancelRequested ? const TransferIdle() : TransferFailed(metadataFailureReason!),
      );
      _cancelRequested = false;
      _activeChannelId = null;
      return;
    }

    if (metadata == null || reassembler == null || nonceForData == null) {
      debugPrint('[TransferManager] ERROR: no signal detected, metadata never received');
      state = state.copyWith(
        phase: _cancelRequested ? const TransferIdle() : const TransferFailed('No signal detected - metadata never received'),
      );
      _cancelRequested = false;
      _activeChannelId = null;
      return;
    }

    state = state.copyWith(phase: const TransferVerifying());
    debugPrint('[TransferManager] verifying and reassembling ${metadata!.fileName}...');
    try {
      final cipherText = reassembler!.assembleBytes();
      final compressed = await cipher.decrypt(cipherText, key: key, nonce: nonceForData!);
      final originalBytes = codec.decode(compressed);
      final verified = verifySha256(originalBytes, metadata!.sha256Hex);
      debugPrint('[TransferManager] sha256 verified=$verified');

      final file = File('${saveDirectory.path}/${metadata!.fileName}');
      await file.writeAsBytes(originalBytes);
      debugPrint('[TransferManager] wrote ${originalBytes.length} byte(s) to ${file.path}');

      final report = TransferReport(
        channel: channelId,
        fileName: metadata!.fileName,
        sizeBytes: metadata!.fileSizeBytes,
        duration: stats.elapsed,
        averageRateBytesPerSec: stats.rateBytesPerSec,
        packetsSent: 0,
        packetsReceived: stats.packetsReceived,
        packetErrors: stats.crcErrors,
        verified: verified,
        filePath: file.path,
      );
      debugPrint('[TransferManager] startReceiveFile() COMPLETE');
      state = state.copyWith(phase: const TransferComplete(), report: report);
    } catch (e) {
      debugPrint('[TransferManager] ERROR: decode failed: $e');
      state = state.copyWith(
        phase: TransferFailed('Decode failed - check passphrase/cipher/codec match: $e'),
      );
    }
    _cancelRequested = false;
    _activeChannelId = null;
  }

  Future<void> cancel() async {
    debugPrint('[TransferManager] cancel() requested (activeChannel=${_activeChannelId?.name})');
    _cancelRequested = true;
    _idleTimer?.cancel();
    final id = _activeChannelId;
    if (id != null) {
      await ref.read(channelRegistryProvider).forId(id).stop();
    }
    if (_receiveStopCompleter != null && !_receiveStopCompleter!.isCompleted) {
      _receiveStopCompleter!.complete();
    }
  }

  void reset() {
    debugPrint('[TransferManager] reset()');
    state = TransferManagerState.initial();
  }
}
