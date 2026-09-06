import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/bitstream/bit_utils.dart';
import 'package:phyra/core/protocol/packet.dart';
import 'package:phyra/core/protocol/packet_header.dart';
import 'package:phyra/core/protocol/packet_stream_parser.dart';
import 'package:phyra/core/protocol/packet_type.dart';

void main() {
  test('parses a clean packet from a bit stream', () async {
    final parser = PacketStreamParser();
    final payload = Uint8List.fromList([72, 69, 76, 76, 79]); 
    final packet = Packet(
      header: PacketHeader(type: PacketType.data, transferId: 1, sequence: 1, payloadLength: payload.length),
      payload: payload,
    );

    final events = <PacketParseEvent>[];
    parser.events.listen(events.add);
    parser.addBits(BitUtils.bytesToBits(packet.toBytes()));
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.single, isA<PacketParsedEvent>());
    expect((events.single as PacketParsedEvent).packet.payload, payload);
  });

  test('recovers after a corrupted packet without losing the next one', () async {
    final parser = PacketStreamParser();
    final packet1 = Packet(
      header: PacketHeader(type: PacketType.data, transferId: 1, sequence: 1, payloadLength: 4),
      payload: Uint8List.fromList([1, 2, 3, 4]),
    );
    final packet2 = Packet(
      header: PacketHeader(type: PacketType.data, transferId: 1, sequence: 2, payloadLength: 4),
      payload: Uint8List.fromList([5, 6, 7, 8]),
    );

    final bytes1 = packet1.toBytes();
    bytes1[bytes1.length - 3] ^= 0xFF; 

    final events = <PacketParseEvent>[];
    parser.events.listen(events.add);
    parser.addBits(BitUtils.bytesToBits(bytes1));
    parser.addBits(BitUtils.bytesToBits(packet2.toBytes()));
    await Future<void>.delayed(Duration.zero);

    expect(events.whereType<PacketCrcErrorEvent>(), hasLength(1));
    final parsed = events.whereType<PacketParsedEvent>().toList();
    expect(parsed, hasLength(1));
    expect(parsed.single.packet.header.sequence, 2);
  });
}
