import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/compression/rle_codec.dart';

void main() {
  final codec = RleCodec();

  test('round-trips repetitive data', () {
    final data = Uint8List.fromList([1, 1, 1, 2, 2, 3, 3, 3, 3]);
    final encoded = codec.encode(data);
    expect(codec.decode(encoded), data);
  });

  test('round-trips empty input', () {
    final data = Uint8List(0);
    expect(codec.decode(codec.encode(data)), data);
  });

  test('splits runs longer than 255', () {
    final data = Uint8List(300)..fillRange(0, 300, 9);
    final encoded = codec.encode(data);
    expect(encoded.length, 4); 
    expect(codec.decode(encoded), data);
  });

  test('round-trips non-repetitive data', () {
    final data = Uint8List.fromList(List.generate(64, (i) => i));
    expect(codec.decode(codec.encode(data)), data);
  });
}
