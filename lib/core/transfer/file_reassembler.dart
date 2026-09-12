import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class FileReassembler {
  FileReassembler({required this.totalPacketCount}) {
    debugPrint('[FileReassembler] created, expecting $totalPacketCount packet(s)');
  }

  final int totalPacketCount;
  final Map<int, Uint8List> _chunksBySequence = {};

  void addChunk(int sequence, Uint8List data) {
    _chunksBySequence[sequence] = data;
  }

  int get receivedPacketCount => _chunksBySequence.length;

  bool get isComplete {
    for (var seq = 1; seq <= totalPacketCount; seq++) {
      if (!_chunksBySequence.containsKey(seq)) return false;
    }
    return true;
  }

  Uint8List assembleBytes() {
    final builder = BytesBuilder();
    for (var seq = 1; seq <= totalPacketCount; seq++) {
      final chunk = _chunksBySequence[seq];
      if (chunk != null) builder.add(chunk);
    }
    final result = builder.toBytes();
    debugPrint('[FileReassembler] assembleBytes() ${_chunksBySequence.length}/$totalPacketCount '
        'chunk(s) -> ${result.length} byte(s)');
    return result;
  }
}
