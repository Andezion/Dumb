import 'dart:typed_data';

abstract final class Yuv420Converter {
  static Uint8List toNv21({
    required Uint8List yBytes,
    required int yBytesPerRow,
    required Uint8List uBytes,
    required int uBytesPerRow,
    required int uPixelStride,
    required Uint8List vBytes,
    required int vBytesPerRow,
    required int vPixelStride,
    required int width,
    required int height,
  }) {
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    final nv21 = Uint8List(width * height + 2 * uvWidth * uvHeight);

    var index = 0;
    for (var row = 0; row < height; row++) {
      final rowStart = row * yBytesPerRow;
      nv21.setRange(index, index + width, yBytes, rowStart);
      index += width;
    }

    for (var row = 0; row < uvHeight; row++) {
      final uRowStart = row * uBytesPerRow;
      final vRowStart = row * vBytesPerRow;
      for (var col = 0; col < uvWidth; col++) {
        nv21[index++] = vBytes[vRowStart + col * vPixelStride];
        nv21[index++] = uBytes[uRowStart + col * uPixelStride];
      }
    }

    return nv21;
  }
}
