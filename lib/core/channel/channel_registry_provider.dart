import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/acoustic_channel.dart';
import '../../platform/acoustic_config.dart';
import '../../platform/optical/optical_channel.dart';
import '../../platform/optical/optical_config.dart';
import 'channel_id.dart';
import 'channel_registry.dart';
import 'not_implemented_channel.dart';
import 'simulated_channel.dart';

final useSimulatedChannelsProvider = StateProvider<bool>((ref) => false);

final channelRegistryProvider = Provider<ChannelRegistry>((ref) {
  final useSimulated = ref.watch(useSimulatedChannelsProvider);
  final acousticConfig = ref.watch(acousticConfigProvider);
  final opticalConfig = ref.watch(opticalConfigProvider);
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
    ChannelId.mechanical: NotImplementedChannel(ChannelId.mechanical),
    ChannelId.magnetic: NotImplementedChannel(ChannelId.magnetic),
    ChannelId.optical: useSimulated
        ? SimulatedChannel(id: ChannelId.optical)
        : OpticalChannel(config: opticalConfig),
    ChannelId.ambientLight: NotImplementedChannel(ChannelId.ambientLight),
  });
});
