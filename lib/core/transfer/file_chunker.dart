import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../protocol/protocol_constants.dart';
import 'sha256_verifier.dart';

class FileChunkResult {
  FileChunkResult({required this.chunks, required this.sha256Hex, required this.totalBytes});

  final List<Uint8List> chunks;
  final String sha256Hex;
  final int totalBytes;
}

abstract final class FileChunker {
  static Future<FileChunkResult> chunk(
    File file, {
    int chunkSize = ProtocolConstants.defaultPayloadBytes,
  }) async {
    final bytes = await file.readAsBytes();
    return chunkBytes(bytes, sha256Hex: sha256Hex(bytes), totalBytes: bytes.length, chunkSize: chunkSize);
  }

  static FileChunkResult chunkBytes(
    Uint8List bytes, {
    required String sha256Hex,
    required int totalBytes,
    int chunkSize = ProtocolConstants.defaultPayloadBytes,
  }) {
    final chunks = <Uint8List>[];
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = min(offset + chunkSize, bytes.length);
      chunks.add(Uint8List.sublistView(bytes, offset, end));
    }
    if (bytes.isEmpty) {
      chunks.add(Uint8List(0));
    }
    return FileChunkResult(
      chunks: chunks,
      sha256Hex: sha256Hex,
      totalBytes: totalBytes,
    );
  }
}
