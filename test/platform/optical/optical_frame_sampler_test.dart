import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/platform/optical/optical_frame_sampler.dart';
import 'package:phyra/platform/optical/optical_grid_frame.dart';

Uint8List _paintBuffer({
  required List<bool> cells,
  required int sensorOrientationDegrees,
  required int bufferWidth,
  required int bufferHeight,
}) {
  const scale = 10;
  final buffer = Uint8List(bufferWidth * bufferHeight);
  for (var row = 0; row < OpticalGridFrame.rows; row++) {
    for (var col = 0; col < OpticalGridFrame.cols; col++) {
      final on = cells[row * OpticalGridFrame.cols + col];
      final value = on ? 255 : 0;

      final dx = col * scale + scale ~/ 2;
      final dy = row * scale + scale ~/ 2;

      final int bx;
      final int by;
      if (sensorOrientationDegrees == 90) {
        bx = dy;
        by = bufferHeight - 1 - dx;
      } else {
        bx = dx;
        by = dy;
      }

      for (var oy = -2; oy <= 2; oy++) {
        for (var ox = -2; ox <= 2; ox++) {
          final px = (bx + ox).clamp(0, bufferWidth - 1);
          final py = (by + oy).clamp(0, bufferHeight - 1);
          buffer[py * bufferWidth + px] = value;
        }
      }
    }
  }
  return buffer;
}

void main() {
  group('OpticalFrameSampler', () {
    test('reports zero contrast and no "on" cells for a blank buffer', () {
      final buffer = Uint8List(320 * 240)..fillRange(0, 320 * 240, 128);
      final result = OpticalFrameSampler.sample(
        yPlane: buffer,
        bytesPerRow: 320,
        bufferWidth: 320,
        bufferHeight: 240,
        sensorOrientationDegrees: 90,
      );
      expect(result.contrast, 0.0);
      expect(result.cells.every((c) => c == false), isTrue);
    });

    test('recovers a known grid through an unrotated (0-degree) buffer', () {
      final cells = OpticalGridFrame.encode(
        frameIndex: 7,
        payload: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]),
      );
      const bufferWidth = OpticalGridFrame.cols * 10;
      const bufferHeight = OpticalGridFrame.rows * 10;
      final buffer = _paintBuffer(
        cells: cells,
        sensorOrientationDegrees: 0,
        bufferWidth: bufferWidth,
        bufferHeight: bufferHeight,
      );

      final result = OpticalFrameSampler.sample(
        yPlane: buffer,
        bytesPerRow: bufferWidth,
        bufferWidth: bufferWidth,
        bufferHeight: bufferHeight,
        sensorOrientationDegrees: 0,
      );

      expect(result.contrast, 1.0);
      expect(result.cells, cells);
      final decoded = OpticalGridFrame.decode(result.cells);
      expect(decoded.isTrustworthy, isTrue);
      expect(decoded.frameIndex, 7);
    });

    test('recovers a known grid through a 90-degree sensor orientation', () {
      final cells = OpticalGridFrame.encode(
        frameIndex: 3,
        payload: Uint8List.fromList([9, 8, 7, 6, 5, 4, 3]),
      );
      const bufferWidth = OpticalGridFrame.rows * 10;
      const bufferHeight = OpticalGridFrame.cols * 10;
      final buffer = _paintBuffer(
        cells: cells,
        sensorOrientationDegrees: 90,
        bufferWidth: bufferWidth,
        bufferHeight: bufferHeight,
      );

      final result = OpticalFrameSampler.sample(
        yPlane: buffer,
        bytesPerRow: bufferWidth,
        bufferWidth: bufferWidth,
        bufferHeight: bufferHeight,
        sensorOrientationDegrees: 90,
      );

      expect(result.contrast, 1.0);
      expect(result.cells, cells);
      final decoded = OpticalGridFrame.decode(result.cells);
      expect(decoded.isTrustworthy, isTrue);
      expect(decoded.frameIndex, 3);
    });
  });
}
