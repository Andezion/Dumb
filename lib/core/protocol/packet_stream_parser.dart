import 'dart:async';

import 'package:flutter/foundation.dart';

import '../bitstream/bit_utils.dart';
import 'packet.dart';

sealed class PacketParseEvent {
  const PacketParseEvent();
}

class PacketParsedEvent extends PacketParseEvent {
  const PacketParsedEvent(this.packet);
  final Packet packet;
}

class PacketCrcErrorEvent extends PacketParseEvent {
  const PacketCrcErrorEvent();
}


class PacketStreamParser {
  final List<int> _bits = [];
  int _searchBitOffset = 0;
  final _controller = StreamController<PacketParseEvent>.broadcast();

  Stream<PacketParseEvent> get events => _controller.stream;

  void addBits(Iterable<int> bits) {
    final added = bits.length;
    _bits.addAll(bits);
    debugPrint('[PacketStreamParser] addBits() +$added bit(s), buffer=${_bits.length} bit(s)');
    _drain();
  }

  void _drain() {
    while (true) {
      final magicBitOffset = _findMagic(_searchBitOffset);
      if (magicBitOffset == null) break;
      debugPrint('[PacketStreamParser] magic found at bit offset $magicBitOffset');

      final candidateBytes = BitUtils.bitsToBytes(_bits.sublist(magicBitOffset));
      final result = PacketParseResult.tryParseAt(Uint8List.fromList(candidateBytes), 0);
      if (result == null) {
        debugPrint('[PacketStreamParser] incomplete packet at offset $magicBitOffset, waiting for more bits');
        _searchBitOffset = magicBitOffset;
        break;
      }

      if (result.crcOk) {
        debugPrint('[PacketStreamParser] packet parsed: type=${result.packet.header.type.name} '
            'seq=${result.packet.header.sequence} payload=${result.packet.payload.length}B');
        _controller.add(PacketParsedEvent(result.packet));
        _searchBitOffset = magicBitOffset + result.consumedBytes * 8;
      } else {
        debugPrint('[PacketStreamParser] CRC error at offset $magicBitOffset, skipping 1 bit');
        _controller.add(const PacketCrcErrorEvent());
        _searchBitOffset = magicBitOffset + 1;
      }
    }
  }

  static const List<int> _magicBits = [0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0]; 

  int? _findMagic(int from) {
    final lastPossible = _bits.length - _magicBits.length;
    for (var offset = from; offset <= lastPossible; offset++) {
      var matches = true;
      for (var i = 0; i < _magicBits.length; i++) {
        if (_bits[offset + i] != _magicBits[i]) {
          matches = false;
          break;
        }
      }
      if (matches) return offset;
    }
    return null;
  }

  Future<void> dispose() => _controller.close();
}
