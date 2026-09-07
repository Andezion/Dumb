import 'dart:typed_data';

import 'cipher_id.dart';

abstract class Cipher {
  CipherId get id;

  int get nonceLength;

  Future<Uint8List> encrypt(Uint8List data, {required Uint8List key, required Uint8List nonce});

  Future<Uint8List> decrypt(Uint8List data, {required Uint8List key, required Uint8List nonce});
}
