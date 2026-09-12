import 'dart:typed_data';

import 'crc8.dart';

abstract final class OpticalGridFrame {
  static const int rows = 10;
  static const int cols = 8;
  static const int cellCount = rows * cols;
  static const int payloadBytesPerFrame = 7;
  static const int payloadBitsPerFrame = payloadBytesPerFrame * 8;

  static const int _syncByte = 0xAA;
  static const int _syncRow = 0;
  static const int _frameIdRow = 1;
  static const int _payloadStartRow = 2;
  static const int _crcRow = 9;

  static List<bool> encode({required int frameIndex, required Uint8List payload}) {
    assert(payload.length == payloadBytesPerFrame);
    final bytes = <int>[frameIndex & 0xFF, ...payload];
    final crc = Crc8.compute(bytes);

    final cells = List<bool>.filled(cellCount, false);
    _writeRow(cells, _syncRow, _syncByte);
    _writeRow(cells, _frameIdRow, bytes[0]);
    for (var i = 0; i < payloadBytesPerFrame; i++) {
      _writeRow(cells, _payloadStartRow + i, bytes[1 + i]);
    }
    _writeRow(cells, _crcRow, crc);
    return cells;
  }

  static void _writeRow(List<bool> cells, int row, int byte) {
    for (var col = 0; col < cols; col++) {
      cells[row * cols + col] = ((byte >> (cols - 1 - col)) & 1) == 1;
    }
  }

  static int _readRow(List<bool> cells, int row) {
    var byte = 0;
    for (var col = 0; col < cols; col++) {
      byte = (byte << 1) | (cells[row * cols + col] ? 1 : 0);
    }
    return byte;
  }

  static OpticalFrameDecodeResult decode(List<bool> cells) {
    assert(cells.length == cellCount);
    final syncByte = _readRow(cells, _syncRow);
    final frameId = _readRow(cells, _frameIdRow);
    final payload = Uint8List(payloadBytesPerFrame);
    for (var i = 0; i < payloadBytesPerFrame; i++) {
      payload[i] = _readRow(cells, _payloadStartRow + i);
    }
    final crc = _readRow(cells, _crcRow);

    final expectedCrc = Crc8.compute([frameId, ...payload]);
    final syncMismatchBits = _popcount(syncByte ^ _syncByte);

    return OpticalFrameDecodeResult(
      frameIndex: frameId,
      payload: payload,
      syncOk: syncMismatchBits == 0,
      syncMismatchBits: syncMismatchBits,
      crcOk: crc == expectedCrc,
    );
  }

  static int _popcount(int value) {
    var count = 0;
    var v = value;
    while (v != 0) {
      count += v & 1;
      v >>= 1;
    }
    return count;
  }
}

class OpticalFrameDecodeResult {
  const OpticalFrameDecodeResult({
    required this.frameIndex,
    required this.payload,
    required this.syncOk,
    required this.syncMismatchBits,
    required this.crcOk,
  });

  final int frameIndex;
  final Uint8List payload;
  final bool syncOk;
  final int syncMismatchBits;
  final bool crcOk;

  bool get isTrustworthy => syncOk && crcOk;
}
