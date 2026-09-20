import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OpticalMode { screenGrid, flash, qrFrames }

extension OpticalModeDisplay on OpticalMode {
  String get title => switch (this) {
        OpticalMode.screenGrid => 'SCREEN GRID',
        OpticalMode.flash => 'FLASH',
        OpticalMode.qrFrames => 'QR FRAMES',
      };

  String get description => switch (this) {
        OpticalMode.screenGrid => 'Custom black/white sync+CRC grid drawn on screen, read by the other camera',
        OpticalMode.flash => 'Torch blinks bits (on = 1, off = 0), read as brightness by the other camera',
        OpticalMode.qrFrames => 'Real QR codes drawn on screen - comparison baseline against the custom grid',
      };
}

class OpticalConfig {
  const OpticalConfig({
    this.mode = OpticalMode.screenGrid,
    this.frameDurationMs = 350,
    this.flashSymbolDurationMs = 120,
    this.qrFrameDurationMs = 500,
  });

  final OpticalMode mode;
  final int frameDurationMs;
  final int flashSymbolDurationMs;
  final int qrFrameDurationMs;

  OpticalConfig copyWith({
    OpticalMode? mode,
    int? frameDurationMs,
    int? flashSymbolDurationMs,
    int? qrFrameDurationMs,
  }) =>
      OpticalConfig(
        mode: mode ?? this.mode,
        frameDurationMs: frameDurationMs ?? this.frameDurationMs,
        flashSymbolDurationMs: flashSymbolDurationMs ?? this.flashSymbolDurationMs,
        qrFrameDurationMs: qrFrameDurationMs ?? this.qrFrameDurationMs,
      );
}

final opticalConfigProvider = StateProvider<OpticalConfig>((ref) => const OpticalConfig());
