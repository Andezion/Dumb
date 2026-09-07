import 'dart:typed_data';

import 'cipher.dart';
import 'cipher_id.dart';

class NoneCipher implements Cipher {
  @override
  CipherId get id => CipherId.none;

  @override
  int get nonceLength => 0;

  @override
  Future<Uint8List> encrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async => data;

  @override
  Future<Uint8List> decrypt(Uint8List data, {required Uint8List key, required Uint8List nonce}) async => data;
}
