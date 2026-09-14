import 'package:flutter_riverpod/flutter_riverpod.dart';

class LightConfig {
  const LightConfig({this.symbolDurationMs = 150});

  final int symbolDurationMs;

  LightConfig copyWith({int? symbolDurationMs}) {
    return LightConfig(
      symbolDurationMs: symbolDurationMs ?? this.symbolDurationMs,
    );
  }
}

final lightConfigProvider = StateProvider<LightConfig>((ref) => const LightConfig());
