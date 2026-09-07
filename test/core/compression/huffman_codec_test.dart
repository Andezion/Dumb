import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phyra/core/compression/huffman_codec.dart';

void main() {
  final codec = HuffmanCodec();

  test('round-trips empty input', () {
    final data = Uint8List(0);
    expect(codec.decode(codec.encode(data)), data);
  });

  test('round-trips a single distinct byte value', () {
    final data = Uint8List(50)..fillRange(0, 50, 42);
    final encoded = codec.encode(data);
    expect(codec.decode(encoded), data);
    expect(encoded.length, lessThan(data.length));
  });

  test('round-trips typical text', () {
    final data = Uint8List.fromList(utf8.encode('the quick brown fox jumps over the lazy dog'));
    expect(codec.decode(codec.encode(data)), data);
  });

  test('compresses repetitive data smaller than the input', () {
    final data = Uint8List.fromList(utf8.encode('abababababababababababababababababababab'));
    final encoded = codec.encode(data);
    expect(encoded.length, lessThan(data.length));
    expect(codec.decode(encoded), data);
  });

  test('falls back to stored form when compression would not help', () {
    final data = Uint8List.fromList([5, 9]);
    final encoded = codec.encode(data);
    expect(encoded[0], 0); 
    expect(encoded.length, data.length + 1);
    expect(codec.decode(encoded), data);
  });
}
