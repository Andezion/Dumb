import 'channel_capabilities.dart';
import 'channel_id.dart';
import 'channel_metrics.dart';
import 'received_symbol.dart';

abstract class PhysicalChannel {
  ChannelId get id;

  Future<ChannelCapabilities> initialize();

  Future<Map<String, double>> calibrate();

  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config});

  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config});

  Stream<ChannelMetrics> get metrics;

  Future<void> stop();
}
