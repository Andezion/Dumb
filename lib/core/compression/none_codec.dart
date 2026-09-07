import 'dart:typed_data';

import 'codec.dart';
import 'codec_id.dart';

class NoneCodec implements Codec {
  @override
  CodecId get id => CodecId.none;

  @override
  Uint8List encode(Uint8List data) => data;

  @override
  Uint8List decode(Uint8List data) => data;
}
