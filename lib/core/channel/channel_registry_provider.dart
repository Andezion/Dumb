import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/acoustic_channel.dart';
import '../../platform/acoustic_config.dart';
import 'channel_id.dart';
import 'channel_registry.dart';
import 'not_implemented_channel.dart';
import 'simulated_channel.dart';

final useSimulatedChannelsProvider = StateProvider<bool>((ref) => false);

final channelRegistryProvider = Provider<ChannelRegistry>((ref) {
  final useSimulated = ref.watch(useSimulatedChannelsProvider);
  final acousticConfig = ref.watch(acousticConfigProvider);
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
    ChannelId.optical: NotImplementedChannel(ChannelId.optical),
    ChannelId.ambientLight: NotImplementedChannel(ChannelId.ambientLight),
  });
});
