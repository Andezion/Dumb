enum CodecId {
  none,
  rle,
  huffman,
}

extension CodecIdDisplay on CodecId {
  String get title => switch (this) {
        CodecId.none => 'NONE',
        CodecId.rle => 'RLE',
        CodecId.huffman => 'HUFFMAN',
      };

  String get description => switch (this) {
        CodecId.none => 'No compression',
        CodecId.rle => 'Run-length encoding - fast, best on repetitive data',
        CodecId.huffman => 'Canonical Huffman coding - general-purpose entropy coding',
      };
}
