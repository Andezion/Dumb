import 'cipher.dart';
import 'cipher_id.dart';

class CipherRegistry {
  CipherRegistry(this._ciphers);

  final Map<CipherId, Cipher> _ciphers;

  Cipher forId(CipherId id) {
    final cipher = _ciphers[id];
    if (cipher == null) {
      throw StateError('No cipher registered for $id');
    }
    return cipher;
  }
}
