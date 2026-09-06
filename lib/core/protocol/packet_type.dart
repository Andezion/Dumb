enum PacketType {
  metadata(0),
  data(1);

  const PacketType(this.wireValue);

  final int wireValue;

  static PacketType? fromWireValue(int value) {
    for (final type in PacketType.values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}
