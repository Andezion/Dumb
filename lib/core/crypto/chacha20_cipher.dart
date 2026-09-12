import 'package:cryptography/cryptography.dart' as pkg;
import 'package:flutter/foundation.dart';

import 'cipher.dart';
import 'cipher_id.dart';

class ChaCha20Cipher implements Cipher {
  ChaCha20Cipher() : _algorithm = pkg.Chacha20(macAlgorithm: pkg.MacAlgorithm.empty);

  final pkg.Cipher _algorithm;

  @override
  CipherId get id => CipherId.chacha20;

  @override
  int get nonceLength => _algorithm.nonceLength;

  @override
  Future<Uint8List> encrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    debugPrint('[ChaCha20Cipher] encrypt() ${data.length} byte(s), nonce ${nonce.length} byte(s)');
    final box = await _algorithm.encrypt(data, secretKey: pkg.SecretKeyData(key), nonce: nonce);
    final result = Uint8List.fromList(box.cipherText);
    debugPrint('[ChaCha20Cipher] encrypt() -> ${result.length} byte(s)');
    return result;
  }

  @override
  Future<Uint8List> decrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    debugPrint('[ChaCha20Cipher] decrypt() ${data.length} byte(s), nonce ${nonce.length} byte(s)');
    final clearText = await _algorithm.decrypt(
      pkg.SecretBox(data, nonce: nonce, mac: pkg.Mac.empty),
      secretKey: pkg.SecretKeyData(key),
    );
    final result = Uint8List.fromList(clearText);
    debugPrint('[ChaCha20Cipher] decrypt() -> ${result.length} byte(s)');
    return result;
  }
}
