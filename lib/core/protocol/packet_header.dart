import 'dart:typed_data';

import 'packet_type.dart';
import 'protocol_constants.dart';

class PacketHeader {
  PacketHeader({
    required this.type,
    required this.transferId,
    required this.sequence,
    required this.payloadLength,
    this.version = ProtocolConstants.version,
  });

  final int version;
  final PacketType type;
  final int transferId;
  final int sequence;
  final int payloadLength;

  Uint8List encode() {
    final bytes = ByteData(ProtocolConstants.headerSize);
    bytes.setUint8(0, ProtocolConstants.magic[0]);
    bytes.setUint8(1, ProtocolConstants.magic[1]);
    bytes.setUint8(2, version);
    bytes.setUint8(3, type.wireValue);
    bytes.setUint32(4, transferId, Endian.big);
    bytes.setUint32(8, sequence, Endian.big);
    bytes.setUint16(12, payloadLength, Endian.big);
    return bytes.buffer.asUint8List();
  }

  static PacketHeader? tryDecode(Uint8List bytes, int offset) {
    if (offset + ProtocolConstants.headerSize > bytes.length) return null;
    if (bytes[offset] != ProtocolConstants.magic[0] ||
        bytes[offset + 1] != ProtocolConstants.magic[1]) {
      return null;
    }
    final view = ByteData.sublistView(bytes, offset, offset + ProtocolConstants.headerSize);
    final version = view.getUint8(2);
    if (version != ProtocolConstants.version) return null;
    final type = PacketType.fromWireValue(view.getUint8(3));
    if (type == null) return null;
    final payloadLength = view.getUint16(12, Endian.big);
    if (payloadLength > ProtocolConstants.maxPayloadBytes) return null;
    return PacketHeader(
      type: type,
      transferId: view.getUint32(4, Endian.big),
      sequence: view.getUint32(8, Endian.big),
      payloadLength: payloadLength,
      version: version,
    );
  }
}
