import 'dart:typed_data';

import 'crc8.dart';

class OpticalQrDecodeResult {
  const OpticalQrDecodeResult({required this.frameIndex, required this.payload, required this.crcOk});

  final int frameIndex;
  final Uint8List payload;
  final bool crcOk;
}

abstract final class OpticalQrFrame {
  static const int payloadBytesPerFrame = 48;
  static const int payloadBitsPerFrame = payloadBytesPerFrame * 8;

  static Uint8List encode({required int frameIndex, required Uint8List payload}) {
    assert(payload.length == payloadBytesPerFrame);
    final bytes = Uint8List(2 + payloadBytesPerFrame);
    bytes[0] = frameIndex & 0xFF;
    bytes[1] = Crc8.compute([bytes[0], ...payload]);
    bytes.setRange(2, bytes.length, payload);
    return bytes;
  }

  static OpticalQrDecodeResult? decode(Uint8List bytes) {
    if (bytes.length != 2 + payloadBytesPerFrame) return null;
    final frameIndex = bytes[0];
    final crc = bytes[1];
    final payload = bytes.sublist(2);
    final expectedCrc = Crc8.compute([frameIndex, ...payload]);
    return OpticalQrDecodeResult(frameIndex: frameIndex, payload: payload, crcOk: crc == expectedCrc);
  }
}
