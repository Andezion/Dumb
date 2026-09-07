import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as pkg;

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
    final box = await _algorithm.encrypt(data, secretKey: pkg.SecretKeyData(key), nonce: nonce);
    return Uint8List.fromList(box.cipherText);
  }

  @override
  Future<Uint8List> decrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async {
    final clearText = await _algorithm.decrypt(
      pkg.SecretBox(data, nonce: nonce, mac: pkg.Mac.empty),
      secretKey: pkg.SecretKeyData(key),
    );
    return Uint8List.fromList(clearText);
  }
}
