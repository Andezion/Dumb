import 'dart:typed_data';

import '../compression/codec_id.dart';
import '../crypto/cipher_id.dart';
import '../crypto/key_derivation.dart';

class SecurityConfig {
  const SecurityConfig({
    required this.cipherId,
    required this.codecId,
    required this.passphrase,
  });

  final CipherId cipherId;
  final CodecId codecId;
  final String passphrase;

  Uint8List get derivedKey => KeyDerivation.deriveKey(passphrase);
}
