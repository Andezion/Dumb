import 'dart:typed_data';

import 'package:crypto/crypto.dart';

String sha256Hex(Uint8List data) => sha256.convert(data).toString();

bool verifySha256(Uint8List data, String expectedHex) =>
    sha256Hex(data).toLowerCase() == expectedHex.toLowerCase();
