import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/crypto/aes_ctr_cipher.dart';
import 'package:phyra/core/crypto/chacha20_cipher.dart';
import 'package:phyra/core/crypto/cipher.dart';
import 'package:phyra/core/crypto/key_derivation.dart';
import 'package:phyra/core/crypto/none_cipher.dart';
import 'package:phyra/core/crypto/xor_stream_cipher.dart';
import 'package:phyra/core/protocol/metadata_envelope.dart';
import 'package:phyra/core/protocol/metadata_payload.dart';

void main() {
  final payload = MetadataPayload(
    fileName: 'secret-plans.txt',
    fileSizeBytes: 1234,
    mimeType: 'text/plain',
    totalPacketCount: 42,
    sha256Hex: '00' * 32,
  );

  for (final cipher in <Cipher>[NoneCipher(), XorStreamCipher(), ChaCha20Cipher(), AesCtrCipher()]) {
    test('round-trips metadata through ${cipher.id}', () async {
      final key = KeyDerivation.deriveKey('shared secret');
      final nonceForData = MetadataEnvelope.generateNonce(cipher.nonceLength);

      final envelope = await MetadataEnvelope.encode(
        payload,
        cipher: cipher,
        key: key,
        nonceForData: nonceForData,
      );

      if (cipher.nonceLength > 0) {
        expect(String.fromCharCodes(envelope).contains(payload.fileName), isFalse);
      }

      final result = await MetadataEnvelope.decode(envelope, cipher: cipher, key: key);
      expect(result.payload.fileName, payload.fileName);
      expect(result.payload.mimeType, payload.mimeType);
      expect(result.payload.fileSizeBytes, payload.fileSizeBytes);
      expect(result.payload.totalPacketCount, payload.totalPacketCount);
      expect(result.payload.sha256Hex, payload.sha256Hex);
      expect(result.nonceForData, nonceForData);
    });
  }

  test('decoding with the wrong passphrase never silently returns the original metadata', () async {
    final cipher = ChaCha20Cipher();
    final rightKey = KeyDerivation.deriveKey('right passphrase');
    final wrongKey = KeyDerivation.deriveKey('wrong passphrase');
    final nonceForData = MetadataEnvelope.generateNonce(cipher.nonceLength);

    final envelope = await MetadataEnvelope.encode(
      payload,
      cipher: cipher,
      key: rightKey,
      nonceForData: nonceForData,
    );

    var matchedOriginal = false;
    try {
      final result = await MetadataEnvelope.decode(envelope, cipher: cipher, key: wrongKey);
      matchedOriginal = result.payload.fileName == payload.fileName &&
          result.payload.totalPacketCount == payload.totalPacketCount;
    } catch (_) {
    }
    expect(matchedOriginal, isFalse);
  });
}
