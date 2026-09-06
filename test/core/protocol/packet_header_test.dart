import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/protocol/packet.dart';
import 'package:phyra/core/protocol/packet_header.dart';
import 'package:phyra/core/protocol/packet_type.dart';

void main() {
  test('encodes and decodes a header round-trip', () {
    final header = PacketHeader(
      type: PacketType.data,
      transferId: 0xDEADBEEF,
      sequence: 7,
      payloadLength: 32,
    );
    final decoded = PacketHeader.tryDecode(header.encode(), 0);
    expect(decoded, isNotNull);
    expect(decoded!.type, PacketType.data);
    expect(decoded.transferId, 0xDEADBEEF);
    expect(decoded.sequence, 7);
    expect(decoded.payloadLength, 32);
  });

  test('rejects a buffer without the magic bytes', () {
    final garbage = Uint8List.fromList(List.filled(20, 0xAA));
    expect(PacketHeader.tryDecode(garbage, 0), isNull);
  });

  test('packet round-trips through toBytes/tryParseAt with a valid CRC', () {
    final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
    final packet = Packet(
      header: PacketHeader(type: PacketType.data, transferId: 1, sequence: 1, payloadLength: payload.length),
      payload: payload,
    );
    final bytes = packet.toBytes();
    final result = PacketParseResult.tryParseAt(bytes, 0);
    expect(result, isNotNull);
    expect(result!.crcOk, isTrue);
    expect(result.packet.payload, payload);
    expect(result.consumedBytes, bytes.length);
  });

  test('detects a corrupted payload via CRC', () {
    final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
    final packet = Packet(
      header: PacketHeader(type: PacketType.data, transferId: 1, sequence: 1, payloadLength: payload.length),
      payload: payload,
    );
    final bytes = packet.toBytes();
    bytes[bytes.length - 5] ^= 0xFF; 
    final result = PacketParseResult.tryParseAt(bytes, 0);
    expect(result, isNotNull);
    expect(result!.crcOk, isFalse);
  });
}
