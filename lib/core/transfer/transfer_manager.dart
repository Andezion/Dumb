import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bitstream/bit_utils.dart';
import '../channel/channel_id.dart';
import '../channel/channel_registry_provider.dart';
import '../protocol/metadata_payload.dart';
import '../protocol/packet.dart';
import '../protocol/packet_header.dart';
import '../protocol/packet_stream_parser.dart';
import '../protocol/packet_type.dart';
import '../protocol/protocol_constants.dart';
import 'file_chunker.dart';
import 'file_reassembler.dart';
import 'sha256_verifier.dart';
import 'transfer_id.dart';
import 'transfer_report.dart';
import 'transfer_state.dart';
import 'transfer_statistics.dart';

const _kInterPacketGap = Duration(milliseconds: 250);

const _kReceiveIdleTimeout = Duration(seconds: 8);

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

  Future<void> startTransmit({required ChannelId channelId, required File file}) async {
    _activeChannelId = channelId;
    _cancelRequested = false;
    final channel = ref.read(channelRegistryProvider).forId(channelId);

    state = TransferManagerState.initial().copyWith(phase: const TransferCalibrating());
    try {
      await channel.calibrate();
    } catch (e) {
      state = state.copyWith(phase: TransferFailed('Calibration failed: $e'));
      _activeChannelId = null;
      return;
    }

    try {
      final chunkResult = await FileChunker.chunk(file);
      final transferId = generateTransferId();
      final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'file.bin';
      final metadata = MetadataPayload(
        fileName: fileName,
        fileSizeBytes: chunkResult.totalBytes,
        mimeType: 'application/octet-stream',
        totalPacketCount: chunkResult.chunks.length,
        sha256Hex: chunkResult.sha256Hex,
      );
      final metadataBytes = metadata.encode();
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
      for (var i = 0; i < ProtocolConstants.metadataRepeatCount; i++) {
        await channel.startTransmit(metadataBits, config: const {});
        await Future.delayed(_kInterPacketGap);
      }

      var stats = state.statistics;
      final totalChunks = chunkResult.chunks.length;
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
        await channel.startTransmit(BitUtils.bytesToBits(packet.toBytes()), config: const {});
        await Future.delayed(_kInterPacketGap);

        stats = stats.copyWith(
          packetsSent: stats.packetsSent + 1,
          bytesTransferred: stats.bytesTransferred + chunk.length,
        );
        state = state.copyWith(statistics: stats, phase: TransferTransmitting((i + 1) / totalChunks));
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
      state = state.copyWith(phase: const TransferComplete(), report: report);
    } catch (e) {
      state = state.copyWith(
        phase: _cancelRequested ? const TransferIdle() : TransferFailed('Transmission failed: $e'),
      );
    } finally {
      _cancelRequested = false;
      _activeChannelId = null;
      await channel.stop();
    }
  }

  Future<void> startReceiveFile({required ChannelId channelId, required Directory saveDirectory}) async {
    _activeChannelId = channelId;
    _cancelRequested = false;
    final channel = ref.read(channelRegistryProvider).forId(channelId);

    state = TransferManagerState.initial().copyWith(phase: const TransferCalibrating());
    try {
      await channel.calibrate();
    } catch (e) {
      state = state.copyWith(phase: TransferFailed('Calibration failed: $e'));
      _activeChannelId = null;
      return;
    }

    state = state.copyWith(phase: const TransferReceiving(0.0));

    final parser = PacketStreamParser();
    MetadataPayload? metadata;
    FileReassembler? reassembler;
    var stats = state.statistics;
    final stopCompleter = Completer<void>();
    _receiveStopCompleter = stopCompleter;

    void resetIdleTimer() {
      _idleTimer?.cancel();
      _idleTimer = Timer(_kReceiveIdleTimeout, () {
        if (!stopCompleter.isCompleted) stopCompleter.complete();
      });
    }

    final parseSubscription = parser.events.listen((event) {
      resetIdleTimer();
      switch (event) {
        case PacketParsedEvent(:final packet):
          if (packet.header.type == PacketType.metadata) {
            if (metadata == null) {
              metadata = MetadataPayload.decode(packet.payload);
              reassembler = FileReassembler(totalPacketCount: metadata!.totalPacketCount);
            }
          } else if (reassembler != null) {
            reassembler!.addChunk(packet.header.sequence, packet.payload);
            stats = stats.copyWith(
              packetsReceived: stats.packetsReceived + 1,
              bytesTransferred: stats.bytesTransferred + packet.payload.length,
            );
            final progress = reassembler!.receivedPacketCount / metadata!.totalPacketCount;
            state = state.copyWith(statistics: stats, phase: TransferReceiving(progress));
            if (reassembler!.isComplete && !stopCompleter.isCompleted) {
              stopCompleter.complete();
            }
          }
        case PacketCrcErrorEvent():
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
    _idleTimer?.cancel();
    _receiveStopCompleter = null;

    await channel.stop();
    await symbolSubscription.cancel();
    await parseSubscription.cancel();
    await parser.dispose();

    if (metadata == null || reassembler == null) {
      state = state.copyWith(
        phase: _cancelRequested ? const TransferIdle() : const TransferFailed('No signal detected — metadata never received'),
      );
      _cancelRequested = false;
      _activeChannelId = null;
      return;
    }

    state = state.copyWith(phase: const TransferVerifying());
    final file = await reassembler!.finalize(saveDirectory, metadata!.fileName);
    final bytes = await file.readAsBytes();
    final verified = verifySha256(bytes, metadata!.sha256Hex);

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
    state = state.copyWith(phase: const TransferComplete(), report: report);
    _cancelRequested = false;
    _activeChannelId = null;
  }

  Future<void> cancel() async {
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
    state = TransferManagerState.initial();
  }
}
