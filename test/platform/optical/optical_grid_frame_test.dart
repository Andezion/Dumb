import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/platform/optical/optical_grid_frame.dart';

void main() {
  group('OpticalGridFrame', () {
    test('round-trips frame index and payload', () {
      final payload = Uint8List.fromList([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD]);
      final cells = OpticalGridFrame.encode(frameIndex: 42, payload: payload);

      expect(cells.length, OpticalGridFrame.cellCount);

      final decoded = OpticalGridFrame.decode(cells);
      expect(decoded.syncOk, isTrue);
      expect(decoded.crcOk, isTrue);
      expect(decoded.frameIndex, 42);
      expect(decoded.payload, payload);
    });

    test('wraps frame index into a byte', () {
      final payload = Uint8List(OpticalGridFrame.payloadBytesPerFrame);
      final cells = OpticalGridFrame.encode(frameIndex: 300, payload: payload);
      final decoded = OpticalGridFrame.decode(cells);
      expect(decoded.frameIndex, 300 & 0xFF);
    });

    test('detects a flipped payload bit via CRC', () {
      final payload = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0]);
      final cells = OpticalGridFrame.encode(frameIndex: 1, payload: payload);

      final corrupted = List<bool>.from(cells);
      corrupted[2 * OpticalGridFrame.cols] = !corrupted[2 * OpticalGridFrame.cols];

      final decoded = OpticalGridFrame.decode(corrupted);
      expect(decoded.syncOk, isTrue);
      expect(decoded.crcOk, isFalse);
    });

    test('rejects a misaligned/no-signal read via the sync row', () {
      final cells = List<bool>.filled(OpticalGridFrame.cellCount, false);
      final decoded = OpticalGridFrame.decode(cells);
      expect(decoded.syncOk, isFalse);
      expect(decoded.isTrustworthy, isFalse);
    });
  });
}
