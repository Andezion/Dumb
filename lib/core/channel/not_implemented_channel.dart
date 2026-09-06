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
  Future<ChannelCapabilities> initialize() async => const ChannelCapabilities(
        hardwareAvailable: false,
        unavailableReason: 'Software not yet implemented for this physical layer',
      );

  @override
  Future<Map<String, double>> calibrate() =>
      throw UnimplementedError('${id.name} channel is not yet implemented');

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) =>
      throw UnimplementedError('${id.name} channel is not yet implemented');

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) =>
      throw UnimplementedError('${id.name} channel is not yet implemented');

  @override
  Stream<ChannelMetrics> get metrics => const Stream.empty();

  @override
  Future<void> stop() async {}
}
