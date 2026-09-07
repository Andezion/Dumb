import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/transfer/file_chunker.dart';
import 'package:phyra/core/transfer/sha256_verifier.dart';

void main() {
  test('splits a file into fixed-size chunks and computes its SHA-256', () async {
    final dir = await Directory.systemTemp.createTemp('phyra_test');
    addTearDown(() => dir.delete(recursive: true));

    final file = File('${dir.path}/sample.txt');
    final content = List.generate(70, (i) => i % 256);
    await file.writeAsBytes(content);

    final result = await FileChunker.chunk(file, chunkSize: 32);

    expect(result.totalBytes, 70);
    expect(result.chunks, hasLength(3));
    expect(result.chunks[0].length, 32);
    expect(result.chunks[2].length, 6);
    expect(result.sha256Hex, sha256Hex(await file.readAsBytes()));
  });

  test('chunkBytes splits already-processed bytes, carrying through original hash/size', () {
    final processedBytes = Uint8List.fromList(List.generate(70, (i) => i % 256));

    final result = FileChunker.chunkBytes(
      processedBytes,
      sha256Hex: 'original-file-hash',
      totalBytes: 123,
      chunkSize: 32,
    );

    expect(result.totalBytes, 123);
    expect(result.sha256Hex, 'original-file-hash');
    expect(result.chunks, hasLength(3));
    expect(result.chunks[0].length, 32);
    expect(result.chunks[2].length, 6);
  });
}
