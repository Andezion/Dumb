import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'codec_id.dart';

class CodecRegistry {
  CodecRegistry(this._codecs) {
    debugPrint('[CodecRegistry] created with ${_codecs.length} codec(s): '
        '${_codecs.keys.map((e) => e.name).join(', ')}');
  }

  final Map<CodecId, Codec> _codecs;

  Codec forId(CodecId id) {
    final codec = _codecs[id];
    if (codec == null) {
      debugPrint('[CodecRegistry] ERROR: no codec registered for ${id.name}');
      throw StateError('No codec registered for $id');
    }
    debugPrint('[CodecRegistry] forId(${id.name}) -> ${codec.runtimeType}');
    return codec;
  }
}
