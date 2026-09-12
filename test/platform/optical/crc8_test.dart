import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/platform/optical/crc8.dart';

void main() {
  group('Crc8', () {
    test('is deterministic for the same input', () {
      final bytes = [0x12, 0x34, 0x56];
      expect(Crc8.compute(bytes), Crc8.compute(bytes));
    });

    test('changes when any byte changes', () {
      final crcA = Crc8.compute([0x00, 0x01, 0x02]);
      final crcB = Crc8.compute([0x00, 0x01, 0x03]);
      expect(crcA, isNot(crcB));
    });

    test('fits in a single byte', () {
      final crc = Crc8.compute([0xFF, 0xFF, 0xFF, 0xFF]);
      expect(crc, inInclusiveRange(0, 0xFF));
    });

    test('empty input crcs to zero', () {
      expect(Crc8.compute(const []), 0);
    });
  });
}
