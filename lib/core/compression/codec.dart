import 'dart:typed_data';

import 'codec_id.dart';

abstract class Codec {
  CodecId get id;

  Uint8List encode(Uint8List data);

  Uint8List decode(Uint8List data);
}
