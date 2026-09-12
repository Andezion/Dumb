import 'package:flutter/foundation.dart';

import 'channel_id.dart';
import 'physical_channel.dart';

class ChannelRegistry {
  ChannelRegistry(this._channels) {
    debugPrint('[ChannelRegistry] created with ${_channels.length} channel(s): '
        '${_channels.keys.map((e) => e.name).join(', ')}');
  }

  final Map<ChannelId, PhysicalChannel> _channels;

  static const Set<ChannelId> implementedChannelIds = {ChannelId.acoustic, ChannelId.optical};

  bool isImplemented(ChannelId id) => implementedChannelIds.contains(id);

  PhysicalChannel forId(ChannelId id) {
    final channel = _channels[id];
    if (channel == null) {
      debugPrint('[ChannelRegistry] ERROR: no channel registered for ${id.name}');
      throw StateError('No channel registered for $id');
    }
    debugPrint('[ChannelRegistry] forId(${id.name}) -> ${channel.runtimeType}');
    return channel;
  }
}
