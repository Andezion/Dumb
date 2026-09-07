import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/crypto/xor_stream_cipher.dart';

void main() {
  test('round-trips through encrypt/decrypt', () async {
    final cipher = XorStreamCipher();
    final key = Uint8List.fromList([1, 2, 3, 4]);
    final nonce = Uint8List(0);
    final data = Uint8List.fromList('the quick brown fox'.codeUnits);

    final cipherText = await cipher.encrypt(data, key: key, nonce: nonce);
    expect(cipherText, isNot(data));

    final plainText = await cipher.decrypt(cipherText, key: key, nonce: nonce);
    expect(plainText, data);
  });

  test('nonceLength is zero', () {
    expect(XorStreamCipher().nonceLength, 0);
  });
}
