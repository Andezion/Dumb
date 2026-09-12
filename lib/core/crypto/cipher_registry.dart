import 'package:flutter/foundation.dart';

import 'cipher.dart';
import 'cipher_id.dart';

class CipherRegistry {
  CipherRegistry(this._ciphers) {
    debugPrint('[CipherRegistry] created with ${_ciphers.length} cipher(s): '
        '${_ciphers.keys.map((e) => e.name).join(', ')}');
  }

  final Map<CipherId, Cipher> _ciphers;

  Cipher forId(CipherId id) {
    final cipher = _ciphers[id];
    if (cipher == null) {
      debugPrint('[CipherRegistry] ERROR: no cipher registered for ${id.name}');
      throw StateError('No cipher registered for $id');
    }
    debugPrint('[CipherRegistry] forId(${id.name}) -> ${cipher.runtimeType}');
    return cipher;
  }
}
