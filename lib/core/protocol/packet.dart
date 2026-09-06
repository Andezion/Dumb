import 'dart:typed_data';

import 'crc32.dart';
import 'packet_header.dart';
import 'protocol_constants.dart';

class Packet {
  Packet({required this.header, required this.payload})
      : assert(header.payloadLength == payload.length);

  final PacketHeader header;
  final Uint8List payload;

  static int totalBytesFor(int payloadLength) =>
      ProtocolConstants.headerSize + payloadLength + ProtocolConstants.crcSize;

  int get totalBytes => totalBytesFor(payload.length);

  Uint8List toBytes() {
    final headerBytes = header.encode();
    final withoutCrc = Uint8List(headerBytes.length + payload.length)
      ..setRange(0, headerBytes.length, headerBytes)
      ..setRange(headerBytes.length, headerBytes.length + payload.length, payload);
    final crc = Crc32.compute(withoutCrc);
    final out = Uint8List(withoutCrc.length + ProtocolConstants.crcSize)
      ..setRange(0, withoutCrc.length, withoutCrc);
    ByteData.sublistView(out, withoutCrc.length).setUint32(0, crc, Endian.big);
    return out;
  }
}

class PacketParseResult {
  PacketParseResult({
    required this.packet,
    required this.crcOk,
    required this.consumedBytes,
  });

  final Packet packet;
  final bool crcOk;
  final int consumedBytes;

  static PacketParseResult? tryParseAt(Uint8List bytes, int offset) {
    final header = PacketHeader.tryDecode(bytes, offset);
    if (header == null) return null;

    final total = Packet.totalBytesFor(header.payloadLength);
    if (offset + total > bytes.length) return null;

    final payloadStart = offset + ProtocolConstants.headerSize;
    final payloadEnd = payloadStart + header.payloadLength;
    final payload = Uint8List.sublistView(bytes, payloadStart, payloadEnd);

    final crcRegion = Uint8List.sublistView(bytes, offset, payloadEnd);
    final storedCrc = ByteData.sublistView(bytes, payloadEnd, payloadEnd + ProtocolConstants.crcSize)
        .getUint32(0, Endian.big);
    final computedCrc = Crc32.compute(crcRegion);

    return PacketParseResult(
      packet: Packet(header: header, payload: Uint8List.fromList(payload)),
      crcOk: storedCrc == computedCrc,
      consumedBytes: total,
    );
  }
}
