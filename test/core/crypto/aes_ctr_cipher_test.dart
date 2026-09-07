import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/crypto/aes_ctr_cipher.dart';

void main() {
  test('round-trips through encrypt/decrypt', () async {
    final cipher = AesCtrCipher();
    final key = Uint8List(32);
    final nonce = Uint8List(cipher.nonceLength);
    final data = Uint8List.fromList('the quick brown fox jumps'.codeUnits);

    final cipherText = await cipher.encrypt(data, key: key, nonce: nonce);
    expect(cipherText, isNot(data));
    expect(cipherText.length, data.length);

    final plainText = await cipher.decrypt(cipherText, key: key, nonce: nonce);
    expect(plainText, data);
  });

  test('distinct nonces produce distinct ciphertexts for the same key/data', () async {
    final cipher = AesCtrCipher();
    final key = Uint8List(32)..fillRange(0, 32, 7);
    final data = Uint8List.fromList('same plaintext, different nonce'.codeUnits);

    final a = await cipher.encrypt(data, key: key, nonce: Uint8List(cipher.nonceLength));
    final b = await cipher.encrypt(data, key: key, nonce: Uint8List(cipher.nonceLength)..fillRange(0, 1, 1));

    expect(a, isNot(b));
  });
}
