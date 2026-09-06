import 'channel_id.dart';
import 'physical_channel.dart';

class ChannelRegistry {
  ChannelRegistry(this._channels);

  final Map<ChannelId, PhysicalChannel> _channels;

  static const Set<ChannelId> implementedChannelIds = {ChannelId.acoustic};

  bool isImplemented(ChannelId id) => implementedChannelIds.contains(id);

  PhysicalChannel forId(ChannelId id) {
    final channel = _channels[id];
    if (channel == null) {
      throw StateError('No channel registered for $id');
    }
    return channel;
  }
}
