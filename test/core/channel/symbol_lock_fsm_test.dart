import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/channel/preamble_sync.dart';
import 'package:phyra/core/channel/symbol_lock_fsm.dart';

void main() {
  group('SymbolLockFsm', () {
    const threshold = 10.0;

    test('stays idle while the signal is below threshold', () {
      final fsm = SymbolLockFsm(threshold);
      expect(fsm.onBlock(0, 1.0), isFalse);
      expect(fsm.onBlock(1, 2.0), isFalse);
      expect(fsm.state, SymbolLockState.idle);
    });

    test('locks after seeing the sync word above threshold, then streams data bits', () {
      final fsm = SymbolLockFsm(threshold);

      for (final bit in PreambleSync.preambleBits) {
        final locked = fsm.onBlock(bit, 20.0);
        expect(locked, isFalse);
      }
      expect(fsm.state, SymbolLockState.searchingSync);

      var locked = false;
      for (final bit in PreambleSync.syncWordBits) {
        locked = fsm.onBlock(bit, 20.0);
      }
      expect(locked, isFalse);
      expect(fsm.state, SymbolLockState.streaming);

      expect(fsm.onBlock(1, 20.0), isTrue);
      expect(fsm.onBlock(0, 1.0), isFalse);
      expect(fsm.onBlock(0, 1.0), isFalse);
      expect(fsm.onBlock(0, 1.0), isFalse);
      expect(fsm.state, SymbolLockState.idle);
    });

    test('tolerates a couple of bit errors in the sync word within the configured tolerance', () {
      final fsm = SymbolLockFsm(threshold, syncHammingTolerance: 2);
      final noisySync = List<int>.from(PreambleSync.syncWordBits);
      noisySync[0] = 1 - noisySync[0];
      noisySync[5] = 1 - noisySync[5];

      fsm.onBlock(0, 20.0);
      for (final bit in noisySync) {
        fsm.onBlock(bit, 20.0);
      }
      expect(fsm.state, SymbolLockState.streaming);
    });

    test('too many bit errors in the sync word does not lock', () {
      final fsm = SymbolLockFsm(threshold, syncHammingTolerance: 2);
      final corrupted = List<int>.from(PreambleSync.syncWordBits);
      for (var i = 0; i < 4; i++) {
        corrupted[i] = 1 - corrupted[i];
      }

      fsm.onBlock(0, 20.0);
      for (final bit in corrupted) {
        fsm.onBlock(bit, 20.0);
      }
      expect(fsm.state, SymbolLockState.searchingSync);
    });

    test('drops back to idle when the sync search loses signal energy', () {
      final fsm = SymbolLockFsm(threshold);
      fsm.onBlock(1, 20.0);
      expect(fsm.state, SymbolLockState.searchingSync);
      fsm.onBlock(1, 1.0);
      expect(fsm.state, SymbolLockState.idle);
    });
  });
}
