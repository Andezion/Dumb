import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/platform/optical/row_brightness_profile.dart';

void main() {
  group('RowBrightnessProfile.compute', () {
    test('returns the exact per-row mean when buckets match rows one-to-one', () {
      const width = 4;
      const height = 3;
      final buffer = Uint8List.fromList([
        10, 10, 10, 10, // row 0
        20, 20, 20, 20, // row 1
        30, 30, 30, 30, // row 2
      ]);

      final profile = RowBrightnessProfile.compute(
        yPlane: buffer,
        bytesPerRow: width,
        bufferWidth: width,
        bufferHeight: height,
        rowBuckets: height,
        columnStride: 1,
      );

      expect(profile, [10.0, 20.0, 30.0]);
    });

    test('averages multiple rows into a single bucket', () {
      const width = 2;
      const height = 4;
      final buffer = Uint8List.fromList([
        0, 0, // row 0
        0, 0, // row 1 -> bucket 0 mean 0
        100, 100, // row 2
        100, 100, // row 3 -> bucket 1 mean 100
      ]);

      final profile = RowBrightnessProfile.compute(
        yPlane: buffer,
        bytesPerRow: width,
        bufferWidth: width,
        bufferHeight: height,
        rowBuckets: 2,
        columnStride: 1,
      );

      expect(profile, [0.0, 100.0]);
    });

    test('returns an empty profile for a zero-sized buffer', () {
      expect(
        RowBrightnessProfile.compute(yPlane: Uint8List(0), bytesPerRow: 0, bufferWidth: 0, bufferHeight: 0),
        isEmpty,
      );
    });
  });

  group('RowBrightnessProfile.countMeanCrossings', () {
    test('counts zero for a flat profile', () {
      expect(RowBrightnessProfile.countMeanCrossings([5.0, 5.0, 5.0]), 0);
    });

    test('counts each crossing of the mean in an alternating profile', () {
      expect(RowBrightnessProfile.countMeanCrossings([0.0, 10.0, 0.0, 10.0]), 3);
    });

    test('returns zero for fewer than two samples', () {
      expect(RowBrightnessProfile.countMeanCrossings([1.0]), 0);
      expect(RowBrightnessProfile.countMeanCrossings([]), 0);
    });
  });
}
