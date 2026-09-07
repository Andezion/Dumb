import 'dart:typed_data';

class FileReassembler {
  FileReassembler({required this.totalPacketCount});

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
    return builder.toBytes();
  }
}
