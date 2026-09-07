import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'codec_id.dart';
import 'codec_registry.dart';
import 'huffman_codec.dart';
import 'none_codec.dart';
import 'rle_codec.dart';

final codecRegistryProvider = Provider<CodecRegistry>((ref) {
  return CodecRegistry({
    CodecId.none: NoneCodec(),
    CodecId.rle: RleCodec(),
    CodecId.huffman: HuffmanCodec(),
  });
});
