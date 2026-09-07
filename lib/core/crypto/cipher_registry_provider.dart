import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aes_ctr_cipher.dart';
import 'chacha20_cipher.dart';
import 'cipher_id.dart';
import 'cipher_registry.dart';
import 'none_cipher.dart';
import 'xor_stream_cipher.dart';

final cipherRegistryProvider = Provider<CipherRegistry>((ref) {
  return CipherRegistry({
    CipherId.none: NoneCipher(),
    CipherId.xor: XorStreamCipher(),
    CipherId.chacha20: ChaCha20Cipher(),
    CipherId.aesCtr: AesCtrCipher(),
  });
});
