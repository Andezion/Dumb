abstract final class Crc8 {
  static const int _polynomial = 0x07;

  static int compute(List<int> bytes) {
    var crc = 0x00;
    for (final byte in bytes) {
      crc ^= byte & 0xFF;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 0x80) != 0 ? ((crc << 1) ^ _polynomial) & 0xFF : (crc << 1) & 0xFF;
      }
    }
    return crc;
  }
}
