import 'dart:typed_data';

abstract final class RowBrightnessProfile {
  static List<double> compute({
    required Uint8List yPlane,
    required int bytesPerRow,
    required int bufferWidth,
    required int bufferHeight,
    int rowBuckets = 60,
    int columnStride = 8,
  }) {
    if (bufferHeight <= 0 || bufferWidth <= 0) return const [];
    final buckets = rowBuckets.clamp(1, bufferHeight);
    final rowsPerBucket = bufferHeight / buckets;
    final profile = List<double>.filled(buckets, 0);

    for (var bucket = 0; bucket < buckets; bucket++) {
      final rowStart = (bucket * rowsPerBucket).floor();
      final rowEnd = ((bucket + 1) * rowsPerBucket).floor().clamp(rowStart + 1, bufferHeight);
      var sum = 0;
      var count = 0;
      for (var row = rowStart; row < rowEnd; row++) {
        final base = row * bytesPerRow;
        for (var col = 0; col < bufferWidth; col += columnStride) {
          sum += yPlane[base + col];
          count++;
        }
      }
      profile[bucket] = count == 0 ? 0.0 : sum / count;
    }
    return profile;
  }

  static int countMeanCrossings(List<double> profile) {
    if (profile.length < 2) return 0;
    final mean = profile.reduce((a, b) => a + b) / profile.length;
    var crossings = 0;
    var wasAbove = profile.first >= mean;
    for (var i = 1; i < profile.length; i++) {
      final above = profile[i] >= mean;
      if (above != wasAbove) crossings++;
      wasAbove = above;
    }
    return crossings;
  }
}
