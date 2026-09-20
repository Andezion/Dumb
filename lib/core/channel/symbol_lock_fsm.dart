import 'preamble_sync.dart';

enum SymbolLockState { idle, searchingSync, streaming }

class SymbolLockFsm {
  SymbolLockFsm(this.noiseThreshold, {this.syncHammingTolerance = 2});

  final double noiseThreshold;
  final int syncHammingTolerance;

  SymbolLockState _state = SymbolLockState.idle;
  SymbolLockState get state => _state;

  final List<int> _recentBits = [];
  int _silenceBlocks = 0;

  static const int silenceBlocksToEndBurst = 3;

  bool onBlock(int bit, double signalLevel) {
    final aboveThreshold = signalLevel > noiseThreshold;
    switch (_state) {
      case SymbolLockState.idle:
        if (aboveThreshold) {
          _state = SymbolLockState.searchingSync;
          _recentBits.clear();
        }
        return false;

      case SymbolLockState.searchingSync:
        if (!aboveThreshold) {
          _state = SymbolLockState.idle;
          _recentBits.clear();
          return false;
        }
        _recentBits.add(bit);
        if (_recentBits.length > PreambleSync.syncWordBits.length) {
          _recentBits.removeAt(0);
        }
        if (_recentBits.length == PreambleSync.syncWordBits.length &&
            PreambleSync.hammingDistance(_recentBits, PreambleSync.syncWordBits) <= syncHammingTolerance) {
          _state = SymbolLockState.streaming;
          _silenceBlocks = 0;
        }
        return false;

      case SymbolLockState.streaming:
        if (!aboveThreshold) {
          _silenceBlocks++;
          if (_silenceBlocks >= silenceBlocksToEndBurst) {
            _state = SymbolLockState.idle;
          }
          return false;
        }
        _silenceBlocks = 0;
        return true;
    }
  }
}
