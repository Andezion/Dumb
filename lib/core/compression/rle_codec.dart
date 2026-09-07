import 'dart:typed_data';

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
    return out.toBytes();
  }

  @override
  Uint8List decode(Uint8List data) {
    final out = BytesBuilder();
    for (var i = 0; i + 1 < data.length; i += 2) {
      out.add(List.filled(data[i + 1], data[i]));
    }
    return out.toBytes();
  }
}
