import 'dart:typed_data';

import 'optical_grid_frame.dart';

class OpticalSampleResult {
  const OpticalSampleResult({required this.cells, required this.contrast});

  final List<bool> cells;

  final double contrast;
}

abstract final class OpticalFrameSampler {
  static OpticalSampleResult sample({
    required Uint8List yPlane,
    required int bytesPerRow,
    required int bufferWidth,
    required int bufferHeight,
    required int sensorOrientationDegrees,
  }) {
    final display = _displaySize(bufferWidth, bufferHeight, sensorOrientationDegrees);
    final displayWidth = display.$1;
    final displayHeight = display.$2;

    final cols = OpticalGridFrame.cols;
    final rows = OpticalGridFrame.rows;

    var cropWidth = displayWidth.toDouble();
    var cropHeight = cropWidth * rows / cols;
    if (cropHeight > displayHeight) {
      cropHeight = displayHeight.toDouble();
      cropWidth = cropHeight * cols / rows;
    }
    final originX = (displayWidth - cropWidth) / 2;
    final originY = (displayHeight - cropHeight) / 2;

    final luma = List<int>.filled(OpticalGridFrame.cellCount, 0);
    for (var row = 0; row < rows; row++) {
      final dy = (originY + (row + 0.5) * cropHeight / rows).round();
      for (var col = 0; col < cols; col++) {
        final dx = (originX + (col + 0.5) * cropWidth / cols).round();
        final buffer = _toBuffer(dx, dy, bufferWidth, bufferHeight, sensorOrientationDegrees);
        final bx = buffer.$1.clamp(0, bufferWidth - 1);
        final by = buffer.$2.clamp(0, bufferHeight - 1);
        final index = by * bytesPerRow + bx;
        luma[row * cols + col] = index >= 0 && index < yPlane.length ? yPlane[index] : 0;
      }
    }

    var minV = 255;
    var maxV = 0;
    for (final v in luma) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final threshold = (minV + maxV) / 2;
    final cells = luma.map((v) => v > threshold).toList();
    final contrast = ((maxV - minV) / 255.0).clamp(0.0, 1.0);

    return OpticalSampleResult(cells: cells, contrast: contrast);
  }

  static double averageLuma(Uint8List yPlane, {int stride = 8}) {
    if (yPlane.isEmpty) return 0;
    var sum = 0;
    var count = 0;
    for (var i = 0; i < yPlane.length; i += stride) {
      sum += yPlane[i];
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  static (int, int) _displaySize(int bufferWidth, int bufferHeight, int rotation) {
    final normalized = ((rotation % 360) + 360) % 360;
    return (normalized == 90 || normalized == 270) ? (bufferHeight, bufferWidth) : (bufferWidth, bufferHeight);
  }

  static (int, int) _toBuffer(int dx, int dy, int bufferWidth, int bufferHeight, int rotation) {
    final normalized = ((rotation % 360) + 360) % 360;
    switch (normalized) {
      case 90:
        return (dy, bufferHeight - 1 - dx);
      case 180:
        return (bufferWidth - 1 - dx, bufferHeight - 1 - dy);
      case 270:
        return (bufferWidth - 1 - dy, dx);
      default:
        return (dx, dy);
    }
  }
}
