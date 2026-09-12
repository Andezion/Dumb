import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class MetadataPayload {
  MetadataPayload({
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.totalPacketCount,
    required this.sha256Hex,
  });

  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final int totalPacketCount;

  final String sha256Hex;

  Uint8List encode() {
    final nameBytes = utf8.encode(fileName);
    final mimeBytes = utf8.encode(mimeType);
    final sha256Bytes = _hexToBytes(sha256Hex);
    assert(sha256Bytes.length == 32);

    final builder = BytesBuilder();
    builder.addByte(nameBytes.length);
    builder.add(nameBytes);
    final sizeField = ByteData(4)..setUint32(0, fileSizeBytes, Endian.big);
    builder.add(sizeField.buffer.asUint8List());
    builder.addByte(mimeBytes.length);
    builder.add(mimeBytes);
    final countField = ByteData(4)..setUint32(0, totalPacketCount, Endian.big);
    builder.add(countField.buffer.asUint8List());
    builder.add(sha256Bytes);
    final result = builder.toBytes();
    debugPrint('[MetadataPayload] encode() $fileName ($fileSizeBytes byte(s)) -> ${result.length} byte(s)');
    return result;
  }

  static MetadataPayload decode(Uint8List bytes) {
    var offset = 0;
    final nameLen = bytes[offset];
    offset += 1;
    final fileName = utf8.decode(bytes.sublist(offset, offset + nameLen));
    offset += nameLen;

    final fileSizeBytes = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
    offset += 4;

    final mimeLen = bytes[offset];
    offset += 1;
    final mimeType = utf8.decode(bytes.sublist(offset, offset + mimeLen));
    offset += mimeLen;

    final totalPacketCount = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
    offset += 4;

    final sha256Bytes = bytes.sublist(offset, offset + 32);
    offset += 32;

    debugPrint('[MetadataPayload] decode() $fileName ($fileSizeBytes byte(s), $totalPacketCount packet(s))');
    return MetadataPayload(
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      totalPacketCount: totalPacketCount,
      sha256Hex: _bytesToHex(sha256Bytes),
    );
  }

  static Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
