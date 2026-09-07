import 'dart:math';
import 'dart:typed_data';

import '../crypto/cipher.dart';
import 'metadata_payload.dart';

class MetadataEnvelopeResult {
  MetadataEnvelopeResult({required this.payload, required this.nonceForData});

  final MetadataPayload payload;
  final Uint8List nonceForData;
}

abstract final class MetadataEnvelope {
  static final Random _random = Random.secure();

  static Future<Uint8List> encode(
    MetadataPayload payload, {
    required Cipher cipher,
    required Uint8List key,
    required Uint8List nonceForData,
  }) async {
    final nonceForMetadata = generateNonce(cipher.nonceLength);
    final cipherText = await cipher.encrypt(payload.encode(), key: key, nonce: nonceForMetadata);

    final builder = BytesBuilder();
    builder.add(nonceForMetadata);
    builder.add(nonceForData);
    builder.add(cipherText);
    return builder.toBytes();
  }

  static Future<MetadataEnvelopeResult> decode(
    Uint8List bytes, {
    required Cipher cipher,
    required Uint8List key,
  }) async {
    final n = cipher.nonceLength;
    if (bytes.length < 2 * n) {
      throw const FormatException('Metadata envelope too short - check passphrase/cipher/codec match');
    }
    final nonceForMetadata = Uint8List.sublistView(bytes, 0, n);
    final nonceForData = Uint8List.fromList(Uint8List.sublistView(bytes, n, 2 * n));
    final cipherText = Uint8List.sublistView(bytes, 2 * n);

    final plainText = await cipher.decrypt(cipherText, key: key, nonce: nonceForMetadata);
    final payload = MetadataPayload.decode(plainText);
    return MetadataEnvelopeResult(payload: payload, nonceForData: nonceForData);
  }

  static Uint8List generateNonce(int length) {
    final nonce = Uint8List(length);
    for (var i = 0; i < length; i++) {
      nonce[i] = _random.nextInt(256);
    }
    return nonce;
  }
}
