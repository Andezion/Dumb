import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/platform/optical/optical_qr_frame.dart';

void main() {
  group('OpticalQrFrame', () {
    test('round-trips frame index and payload with a valid CRC', () {
      final payload = Uint8List.fromList(List<int>.generate(OpticalQrFrame.payloadBytesPerFrame, (i) => i * 3 + 1));
      final encoded = OpticalQrFrame.encode(frameIndex: 42, payload: payload);

      final decoded = OpticalQrFrame.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.frameIndex, 42);
      expect(decoded.payload, payload);
      expect(decoded.crcOk, isTrue);
    });

    test('wraps frame index into a single byte', () {
      final payload = Uint8List(OpticalQrFrame.payloadBytesPerFrame);
      final encoded = OpticalQrFrame.encode(frameIndex: 300, payload: payload);
      expect(OpticalQrFrame.decode(encoded)!.frameIndex, 300 & 0xFF);
    });

    test('detects a corrupted payload via CRC', () {
      final payload = Uint8List.fromList(List<int>.filled(OpticalQrFrame.payloadBytesPerFrame, 7));
      final encoded = OpticalQrFrame.encode(frameIndex: 1, payload: payload);
      encoded[encoded.length - 1] ^= 0xFF;

      final decoded = OpticalQrFrame.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.crcOk, isFalse);
    });

    test('returns null for bytes that are not one of our frames', () {
      expect(OpticalQrFrame.decode(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });
}
