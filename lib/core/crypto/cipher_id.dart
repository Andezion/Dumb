enum CipherId {
  none,
  xor,
  chacha20,
  aesCtr,
}

extension CipherIdDisplay on CipherId {
  String get title => switch (this) {
        CipherId.none => 'NONE',
        CipherId.xor => 'XOR (TOY)',
        CipherId.chacha20 => 'CHACHA20',
        CipherId.aesCtr => 'AES-256-CTR',
      };

  String get description => switch (this) {
        CipherId.none => 'No encryption - signal is fully readable',
        CipherId.xor => 'Repeating-key XOR - intentionally weak, breakable by frequency analysis',
        CipherId.chacha20 => 'ChaCha20 stream cipher, 256-bit key',
        CipherId.aesCtr => 'AES-256 in counter mode',
      };
}
