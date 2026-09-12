import 'package:cryptography/cryptography.dart' as pkg;
import 'package:flutter/foundation.dart';

import 'cipher.dart';
import 'cipher_id.dart';

class AesCtrCipher implements Cipher {
  AesCtrCipher() : _algorithm = pkg.AesCtr.with256bits(macAlgorithm: pkg.MacAlgorithm.empty);

  final pkg.Cipher _algorithm;

  @override
  CipherId get id => CipherId.aesCtr;

  @override
  int get nonceLength => _algorithm.nonceLength;

  @override
  Future<Uint8List> encrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    debugPrint('[AesCtrCipher] encrypt() ${data.length} byte(s), nonce ${nonce.length} byte(s)');
    final box = await _algorithm.encrypt(data, secretKey: pkg.SecretKeyData(key), nonce: nonce);
    final result = Uint8List.fromList(box.cipherText);
    debugPrint('[AesCtrCipher] encrypt() -> ${result.length} byte(s)');
    return result;
  }

  @override
  Future<Uint8List> decrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    debugPrint('[AesCtrCipher] decrypt() ${data.length} byte(s), nonce ${nonce.length} byte(s)');
    final clearText = await _algorithm.decrypt(
      pkg.SecretBox(data, nonce: nonce, mac: pkg.Mac.empty),
      secretKey: pkg.SecretKeyData(key),
    );
    final result = Uint8List.fromList(clearText);
    debugPrint('[AesCtrCipher] decrypt() -> ${result.length} byte(s)');
    return result;
  }
}
