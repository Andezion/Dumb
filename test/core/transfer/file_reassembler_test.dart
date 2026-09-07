import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/transfer/file_reassembler.dart';

void main() {
  test('reassembles chunks in order regardless of arrival order', () async {
    final reassembler = FileReassembler(totalPacketCount: 3);
    reassembler.addChunk(2, Uint8List.fromList([4, 5, 6]));
    reassembler.addChunk(1, Uint8List.fromList([1, 2, 3]));
    reassembler.addChunk(3, Uint8List.fromList([7, 8]));

    expect(reassembler.isComplete, isTrue);
    expect(reassembler.assembleBytes(), [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('reports incomplete when a sequence is missing', () {
    final reassembler = FileReassembler(totalPacketCount: 3);
    reassembler.addChunk(1, Uint8List.fromList([1]));
    reassembler.addChunk(3, Uint8List.fromList([3]));

    expect(reassembler.isComplete, isFalse);
    expect(reassembler.receivedPacketCount, 2);
  });
}
