import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/acoustic_channel.dart';
import '../../platform/acoustic_config.dart';
import '../../platform/light_channel.dart';
import '../../platform/light_config.dart';
import '../../platform/magnetic_channel.dart';
import '../../platform/magnetic_config.dart';
import '../../platform/mechanical_channel.dart';
import '../../platform/mechanical_config.dart';
import '../../platform/optical/optical_channel.dart';
import '../../platform/optical/optical_config.dart';
import 'channel_id.dart';
import 'channel_registry.dart';
import 'simulated_channel.dart';

final useSimulatedChannelsProvider = StateProvider<bool>((ref) => false);

final channelRegistryProvider = Provider<ChannelRegistry>((ref) {
  final useSimulated = ref.watch(useSimulatedChannelsProvider);
  final acousticConfig = ref.watch(acousticConfigProvider);
  final opticalConfig = ref.watch(opticalConfigProvider);
  final mechanicalConfig = ref.watch(mechanicalConfigProvider);
  final magneticConfig = ref.watch(magneticConfigProvider);
  final lightConfig = ref.watch(lightConfigProvider);
  debugPrint('[ChannelRegistryProvider] rebuilding registry (useSimulated=$useSimulated)');
  return ChannelRegistry({
    ChannelId.acoustic: useSimulated
        ? SimulatedChannel(id: ChannelId.acoustic)
        : AcousticChannel(
            freq0Hz: acousticConfig.freq0Hz,
            freq1Hz: acousticConfig.freq1Hz,
            symbolDurationMs: acousticConfig.symbolDurationMs,
            sampleRate: acousticConfig.sampleRate,
          ),
    ChannelId.mechanical: useSimulated
        ? SimulatedChannel(id: ChannelId.mechanical)
        : MechanicalChannel(symbolDurationMs: mechanicalConfig.symbolDurationMs),
    ChannelId.magnetic: useSimulated
        ? SimulatedChannel(id: ChannelId.magnetic)
        : MagneticChannel(toneHz: magneticConfig.toneHz, symbolDurationMs: magneticConfig.symbolDurationMs),
    ChannelId.optical: useSimulated
        ? SimulatedChannel(id: ChannelId.optical)
        : OpticalChannel(config: opticalConfig),
    ChannelId.ambientLight: useSimulated
        ? SimulatedChannel(id: ChannelId.ambientLight)
        : LightChannel(symbolDurationMs: lightConfig.symbolDurationMs),
  });
});
