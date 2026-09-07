import 'dart:typed_data';

import 'codec.dart';
import 'codec_id.dart';

class HuffmanCodec implements Codec {
  @override
  CodecId get id => CodecId.huffman;

  @override
  Uint8List encode(Uint8List data) {
    if (data.isEmpty) return Uint8List.fromList(const [0]);

    final freq = List<int>.filled(256, 0);
    for (final b in data) {
      freq[b]++;
    }
    final distinctSymbols = <int>[for (var i = 0; i < 256; i++) if (freq[i] > 0) i];

    final Uint8List candidate;
    if (distinctSymbols.length == 1) {
      final body = BytesBuilder();
      body.addByte(1);
      _writeUint32(body, data.length);
      body.addByte(distinctSymbols.single);
      candidate = body.toBytes();
    } else {
      candidate = _encodeGeneral(data, freq, distinctSymbols);
    }

    if (candidate.length >= data.length + 1) {
      final stored = BytesBuilder();
      stored.addByte(0);
      stored.add(data);
      return stored.toBytes();
    }
    return candidate;
  }

  @override
  Uint8List decode(Uint8List data) {
    if (data.isEmpty) return Uint8List(0);
    final tag = data[0];
    switch (tag) {
      case 0:
        return Uint8List.sublistView(data, 1);
      case 1:
        final origLen = _readUint32(data, 1);
        final symbol = data[5];
        return Uint8List(origLen)..fillRange(0, origLen, symbol);
      case 2:
        return _decodeGeneral(data);
      default:
        throw FormatException('Unknown Huffman codec tag $tag');
    }
  }

  Uint8List _encodeGeneral(Uint8List data, List<int> freq, List<int> distinctSymbols) {
    final lengths = List<int>.filled(256, 0);
    final tree = _buildTree(freq, distinctSymbols);
    _collectLengths(tree, 0, lengths);
    final codes = _canonicalCodes(distinctSymbols, lengths);

    final body = BytesBuilder();
    body.addByte(2);
    _writeUint32(body, data.length);
    body.addByte(distinctSymbols.length - 1);
    final sortedSymbols = [...distinctSymbols]..sort();
    for (final s in sortedSymbols) {
      body.addByte(s);
      body.addByte(lengths[s]);
    }

    final writer = _BitWriter();
    for (final b in data) {
      final code = codes[b]!;
      writer.writeBits(code.code, code.length);
    }
    body.add(writer.finish());
    return body.toBytes();
  }

  Uint8List _decodeGeneral(Uint8List data) {
    final origLen = _readUint32(data, 1);
    if (origLen == 0) return Uint8List(0);

    final symbolCount = data[5] + 1;
    var offset = 6;
    final symbols = <int>[];
    final lengths = List<int>.filled(256, 0);
    for (var i = 0; i < symbolCount; i++) {
      final symbol = data[offset];
      final length = data[offset + 1];
      symbols.add(symbol);
      lengths[symbol] = length;
      offset += 2;
    }
    final codes = _canonicalCodes(symbols, lengths);

    final decodeMap = <int, Map<int, int>>{};
    for (final entry in codes.entries) {
      decodeMap.putIfAbsent(entry.value.length, () => {})[entry.value.code] = entry.key;
    }

    final reader = _BitReader(Uint8List.sublistView(data, offset));
    final out = Uint8List(origLen);
    for (var i = 0; i < origLen; i++) {
      var code = 0;
      var length = 0;
      int? symbol;
      while (symbol == null) {
        code = (code << 1) | reader.readBit();
        length++;
        if (length > 32) {
          throw const FormatException('Huffman decode desynchronized - check passphrase/cipher/codec match');
        }
        symbol = decodeMap[length]?[code];
      }
      out[i] = symbol;
    }
    return out;
  }

  _HuffmanNode _buildTree(List<int> freq, List<int> distinctSymbols) {
    final nodes = <_HuffmanNode>[for (final s in distinctSymbols) _HuffmanNode.leaf(s, freq[s])];
    while (nodes.length > 1) {
      nodes.sort((a, b) => a.frequency.compareTo(b.frequency));
      final a = nodes.removeAt(0);
      final b = nodes.removeAt(0);
      nodes.add(_HuffmanNode.branch(a, b));
    }
    return nodes.single;
  }

  void _collectLengths(_HuffmanNode node, int depth, List<int> lengths) {
    final left = node.left;
    final right = node.right;
    if (left == null || right == null) {
      lengths[node.symbol] = depth;
      return;
    }
    _collectLengths(left, depth + 1, lengths);
    _collectLengths(right, depth + 1, lengths);
  }

  Map<int, _Code> _canonicalCodes(List<int> symbols, List<int> lengths) {
    final sorted = [...symbols]..sort((a, b) {
        final byLength = lengths[a].compareTo(lengths[b]);
        if (byLength != 0) return byLength;
        return a.compareTo(b);
      });
    final codes = <int, _Code>{};
    var code = 0;
    var prevLength = lengths[sorted.first];
    for (final symbol in sorted) {
      final length = lengths[symbol];
      code <<= (length - prevLength);
      codes[symbol] = _Code(code, length);
      code += 1;
      prevLength = length;
    }
    return codes;
  }

  void _writeUint32(BytesBuilder builder, int value) {
    final bytes = ByteData(4)..setUint32(0, value, Endian.big);
    builder.add(bytes.buffer.asUint8List());
  }

  int _readUint32(Uint8List data, int offset) =>
      ByteData.sublistView(data, offset, offset + 4).getUint32(0, Endian.big);
}

class _Code {
  const _Code(this.code, this.length);
  final int code;
  final int length;
}

class _HuffmanNode {
  _HuffmanNode.leaf(this.symbol, this.frequency)
      : left = null,
        right = null;

  _HuffmanNode.branch(this.left, this.right)
      : symbol = -1,
        frequency = left!.frequency + right!.frequency;

  final int symbol;
  final int frequency;
  final _HuffmanNode? left;
  final _HuffmanNode? right;
}

class _BitWriter {
  final BytesBuilder _bytes = BytesBuilder();
  int _current = 0;
  int _bitCount = 0;

  void writeBits(int value, int length) {
    for (var i = length - 1; i >= 0; i--) {
      final bit = (value >> i) & 1;
      _current = (_current << 1) | bit;
      _bitCount++;
      if (_bitCount == 8) {
        _bytes.addByte(_current);
        _current = 0;
        _bitCount = 0;
      }
    }
  }

  Uint8List finish() {
    if (_bitCount > 0) {
      _current <<= (8 - _bitCount);
      _bytes.addByte(_current);
      _current = 0;
      _bitCount = 0;
    }
    return _bytes.toBytes();
  }
}

class _BitReader {
  _BitReader(this._bytes);

  final Uint8List _bytes;
  int _byteIndex = 0;
  int _bitIndex = 0;

  int readBit() {
    final byte = _bytes[_byteIndex];
    final bit = (byte >> (7 - _bitIndex)) & 1;
    _bitIndex++;
    if (_bitIndex == 8) {
      _bitIndex = 0;
      _byteIndex++;
    }
    return bit;
  }
}
