import 'package:flutter_riverpod/flutter_riverpod.dart';

class OpticalConfig {
  const OpticalConfig({this.frameDurationMs = 350});

  final int frameDurationMs;

  OpticalConfig copyWith({int? frameDurationMs}) =>
      OpticalConfig(frameDurationMs: frameDurationMs ?? this.frameDurationMs);
}

final opticalConfigProvider = StateProvider<OpticalConfig>((ref) => const OpticalConfig());
