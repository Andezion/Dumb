import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

abstract final class KeyDerivation {
  static Uint8List deriveKey(String passphrase) {
    final key = Uint8List.fromList(sha256.convert(utf8.encode(passphrase)).bytes);
    debugPrint('[KeyDerivation] deriveKey() passphrase length=${passphrase.length} -> ${key.length}-byte key');
    return key;
  }
}
