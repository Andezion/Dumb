import 'dart:typed_data';

abstract final class BitUtils {
  static List<int> bytesToBits(Uint8List bytes) {
    final bits = List<int>.filled(bytes.length * 8, 0);
    var i = 0;
    for (final byte in bytes) {
      for (var b = 7; b >= 0; b--) {
        bits[i++] = (byte >> b) & 1;
      }
    }
    return bits;
  }

  static Uint8List bitsToBytes(List<int> bits) {
    final byteCount = bits.length ~/ 8;
    final bytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      var value = 0;
      for (var b = 0; b < 8; b++) {
        value = (value << 1) | (bits[i * 8 + b] & 1);
      }
      bytes[i] = value;
    }
    return bytes;
  }

  static List<int> asciiToBits(String text) =>
      bytesToBits(Uint8List.fromList(text.codeUnits));
}
