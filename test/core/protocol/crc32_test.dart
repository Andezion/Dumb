import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/protocol/crc32.dart';

void main() {
  test('matches the standard CRC-32/ISO-HDLC check value', () {
    final bytes = Uint8List.fromList(utf8.encode('123456789'));
    expect(Crc32.compute(bytes), 0xCBF43926);
  });
}
