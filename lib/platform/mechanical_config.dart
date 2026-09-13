import 'package:flutter_riverpod/flutter_riverpod.dart';

class MechanicalConfig {
  const MechanicalConfig({this.symbolDurationMs = 150});

  final int symbolDurationMs;

  MechanicalConfig copyWith({int? symbolDurationMs}) {
    return MechanicalConfig(symbolDurationMs: symbolDurationMs ?? this.symbolDurationMs);
  }
}

final mechanicalConfigProvider = StateProvider<MechanicalConfig>((ref) => const MechanicalConfig());
