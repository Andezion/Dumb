import 'package:flutter_riverpod/flutter_riverpod.dart';

class MagneticConfig {
  const MagneticConfig({this.toneHz = 40, this.symbolDurationMs = 150});

  final int toneHz;
  final int symbolDurationMs;

  MagneticConfig copyWith({int? toneHz, int? symbolDurationMs}) {
    return MagneticConfig(
      toneHz: toneHz ?? this.toneHz,
      symbolDurationMs: symbolDurationMs ?? this.symbolDurationMs,
    );
  }
}

final magneticConfigProvider = StateProvider<MagneticConfig>((ref) => const MagneticConfig());
