import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

String sha256Hex(Uint8List data) {
  final hex = sha256.convert(data).toString();
  debugPrint('[Sha256Verifier] sha256Hex() ${data.length} byte(s) -> $hex');
  return hex;
}

bool verifySha256(Uint8List data, String expectedHex) {
  final matches = sha256Hex(data).toLowerCase() == expectedHex.toLowerCase();
  debugPrint('[Sha256Verifier] verifySha256() matches=$matches');
  return matches;
}
