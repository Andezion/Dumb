import 'codec.dart';
import 'codec_id.dart';

class CodecRegistry {
  CodecRegistry(this._codecs);

  final Map<CodecId, Codec> _codecs;

  Codec forId(CodecId id) {
    final codec = _codecs[id];
    if (codec == null) {
      throw StateError('No codec registered for $id');
    }
    return codec;
  }
}
