import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class KeyDerivation {
  static Uint8List deriveKey(String passphrase) =>
      Uint8List.fromList(sha256.convert(utf8.encode(passphrase)).bytes);
}
