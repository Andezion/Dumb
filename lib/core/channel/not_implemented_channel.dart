import 'package:flutter/foundation.dart';

import 'channel_capabilities.dart';
import 'channel_id.dart';
import 'channel_metrics.dart';
import 'physical_channel.dart';
import 'received_symbol.dart';

class NotImplementedChannel implements PhysicalChannel {
  NotImplementedChannel(this.id);

  @override
  final ChannelId id;

  @override
  Future<ChannelCapabilities> initialize() async {
    debugPrint('[NotImplementedChannel:${id.name}] initialize() -> hardware unavailable');
    return const ChannelCapabilities(
      hardwareAvailable: false,
      unavailableReason: 'Software not yet implemented for this physical layer',
    );
  }

  @override
  Future<Map<String, double>> calibrate() {
    debugPrint('[NotImplementedChannel:${id.name}] calibrate() -> UnimplementedError');
    throw UnimplementedError('${id.name} channel is not yet implemented');
  }

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) {
    debugPrint('[NotImplementedChannel:${id.name}] startTransmit() -> UnimplementedError');
    throw UnimplementedError('${id.name} channel is not yet implemented');
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    debugPrint('[NotImplementedChannel:${id.name}] startReceive() -> UnimplementedError');
    throw UnimplementedError('${id.name} channel is not yet implemented');
  }

  @override
  Stream<ChannelMetrics> get metrics => const Stream.empty();

  @override
  Future<void> stop() async {
    debugPrint('[NotImplementedChannel:${id.name}] stop()');
  }
}
