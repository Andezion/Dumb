import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'codec_id.dart';

class RleCodec implements Codec {
  @override
  CodecId get id => CodecId.rle;

  @override
  Uint8List encode(Uint8List data) {
    final out = BytesBuilder();
    var i = 0;
    while (i < data.length) {
      final value = data[i];
      var runLength = 1;
      while (i + runLength < data.length && data[i + runLength] == value && runLength < 255) {
        runLength++;
      }
      out.addByte(value);
      out.addByte(runLength);
      i += runLength;
    }
    final result = out.toBytes();
    debugPrint('[RleCodec] encode() ${data.length} byte(s) -> ${result.length} byte(s)');
    return result;
  }

  @override
  Uint8List decode(Uint8List data) {
    final out = BytesBuilder();
    for (var i = 0; i + 1 < data.length; i += 2) {
      out.add(List.filled(data[i + 1], data[i]));
    }
    final result = out.toBytes();
    debugPrint('[RleCodec] decode() ${data.length} byte(s) -> ${result.length} byte(s)');
    return result;
  }
}
