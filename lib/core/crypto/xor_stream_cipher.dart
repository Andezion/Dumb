import 'package:flutter/foundation.dart';

import 'cipher.dart';
import 'cipher_id.dart';

class XorStreamCipher implements Cipher {
  @override
  CipherId get id => CipherId.xor;

  @override
  int get nonceLength => 0;

  @override
  Future<Uint8List> encrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    debugPrint('[XorStreamCipher] encrypt() ${data.length} byte(s) with ${key.length}-byte key');
    return _apply(data, key);
  }

  @override
  Future<Uint8List> decrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    debugPrint('[XorStreamCipher] decrypt() ${data.length} byte(s) with ${key.length}-byte key');
    return _apply(data, key);
  }

  Uint8List _apply(Uint8List data, Uint8List key) {
    final out = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      out[i] = data[i] ^ key[i % key.length];
    }
    return out;
  }
}
