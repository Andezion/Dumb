import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/platform/optical/yuv420_to_nv21.dart';

void main() {
  group('Yuv420Converter.toNv21', () {
    test('copies a contiguous Y plane and interleaves V before U', () {
      const width = 4;
      const height = 2;
      final y = Uint8List.fromList([10, 11, 12, 13, 20, 21, 22, 23]);
      final u = Uint8List.fromList([100, 101]);
      final v = Uint8List.fromList([200, 201]);

      final nv21 = Yuv420Converter.toNv21(
        yBytes: y,
        yBytesPerRow: width,
        uBytes: u,
        uBytesPerRow: width ~/ 2,
        uPixelStride: 1,
        vBytes: v,
        vBytesPerRow: width ~/ 2,
        vPixelStride: 1,
        width: width,
        height: height,
      );

      expect(nv21.length, width * height + 2 * (width ~/ 2) * (height ~/ 2));
      expect(nv21.sublist(0, 8), y);
      expect(nv21.sublist(8), [200, 100, 201, 101]);
    });

    test('respects row stride padding and non-unit chroma pixel stride', () {
      const width = 4;
      const height = 2;
      final y = Uint8List.fromList([1, 2, 3, 4, 0, 5, 6, 7, 8, 0]);
      final u = Uint8List.fromList([50, 0, 51, 0]);
      final v = Uint8List.fromList([60, 0, 61, 0]);

      final nv21 = Yuv420Converter.toNv21(
        yBytes: y,
        yBytesPerRow: 5,
        uBytes: u,
        uBytesPerRow: 4,
        uPixelStride: 2,
        vBytes: v,
        vBytesPerRow: 4,
        vPixelStride: 2,
        width: width,
        height: height,
      );

      expect(nv21.sublist(0, 8), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(nv21.sublist(8), [60, 50, 61, 51]);
    });
  });
}
