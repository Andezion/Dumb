import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/channel/preamble_sync.dart';

void main() {
  group('PreambleSync', () {
    test('header concatenates preamble then sync word', () {
      final header = PreambleSync.header();
      expect(header.length, PreambleSync.preambleBits.length + PreambleSync.syncWordBits.length);
      expect(header.sublist(0, PreambleSync.preambleBits.length), PreambleSync.preambleBits);
      expect(header.sublist(PreambleSync.preambleBits.length), PreambleSync.syncWordBits);
    });

    test('hammingDistance is zero for identical lists', () {
      expect(PreambleSync.hammingDistance(PreambleSync.syncWordBits, PreambleSync.syncWordBits), 0);
    });

    test('hammingDistance counts differing bits', () {
      expect(PreambleSync.hammingDistance([1, 1, 0, 0], [1, 0, 0, 1]), 2);
    });

    test('hammingDistance rejects unequal-length lists', () {
      expect(() => PreambleSync.hammingDistance([1, 0], [1, 0, 1]), throwsA(isA<AssertionError>()));
    });
  });
}
