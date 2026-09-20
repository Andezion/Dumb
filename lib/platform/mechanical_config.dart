import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MechanicalMode { ook, pulseCount }

extension MechanicalModeDisplay on MechanicalMode {
  String get title => switch (this) {
        MechanicalMode.ook => 'ON-OFF KEYING',
        MechanicalMode.pulseCount => 'PULSE COUNT',
      };

  String get description => switch (this) {
        MechanicalMode.ook => 'Pulse = 1, silence = 0 - one bit per symbol window',
        MechanicalMode.pulseCount => '1-4 pulses per window encode a 2-bit symbol - stands in for frequency',
      };

  String get wireValue => switch (this) {
        MechanicalMode.ook => 'ook',
        MechanicalMode.pulseCount => 'pulseCount',
      };
}

class MechanicalConfig {
  const MechanicalConfig({
    this.mode = MechanicalMode.ook,
    this.symbolDurationMs = 150,
    this.pulseWindowMs = 500,
  });

  final MechanicalMode mode;
  final int symbolDurationMs;
  final int pulseWindowMs;

  MechanicalConfig copyWith({MechanicalMode? mode, int? symbolDurationMs, int? pulseWindowMs}) {
    return MechanicalConfig(
      mode: mode ?? this.mode,
      symbolDurationMs: symbolDurationMs ?? this.symbolDurationMs,
      pulseWindowMs: pulseWindowMs ?? this.pulseWindowMs,
    );
  }
}

final mechanicalConfigProvider = StateProvider<MechanicalConfig>((ref) => const MechanicalConfig());
