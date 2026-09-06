import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcousticConfig {
  const AcousticConfig({
    this.freq0Hz = 4000,
    this.freq1Hz = 6000,
    this.symbolDurationMs = 30,
    this.sampleRate = 44100,
  });

  final int freq0Hz;
  final int freq1Hz;
  final int symbolDurationMs;
  final int sampleRate;

  AcousticConfig copyWith({int? freq0Hz, int? freq1Hz, int? symbolDurationMs, int? sampleRate}) {
    return AcousticConfig(
      freq0Hz: freq0Hz ?? this.freq0Hz,
      freq1Hz: freq1Hz ?? this.freq1Hz,
      symbolDurationMs: symbolDurationMs ?? this.symbolDurationMs,
      sampleRate: sampleRate ?? this.sampleRate,
    );
  }
}

final acousticConfigProvider = StateProvider<AcousticConfig>((ref) => const AcousticConfig());
