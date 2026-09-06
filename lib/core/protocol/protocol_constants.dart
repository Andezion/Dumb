abstract final class ProtocolConstants {
  static const List<int> magic = [0x50, 0x48];

  static const int version = 1;

  static const int headerSize = 14;
  static const int crcSize = 4;
  static const int minPacketSize = headerSize + crcSize;

  static const int defaultPayloadBytes = 32;
  static const int maxPayloadBytes = 0xFFFF;

  static const int metadataRepeatCount = 3;
}
