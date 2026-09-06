import 'dart:async';

import 'package:flutter/services.dart';

import '../core/channel/channel_capabilities.dart';
import '../core/channel/channel_id.dart';
import '../core/channel/channel_metrics.dart';
import '../core/channel/physical_channel.dart';
import '../core/channel/received_symbol.dart';
import 'channel_method_bridge.dart';
import 'symbol_event_bridge.dart';
import 'telemetry_event_bridge.dart';

class AcousticChannel implements PhysicalChannel {
  AcousticChannel({
    this.freq0Hz = 4000,
    this.freq1Hz = 6000,
    this.symbolDurationMs = 30,
    this.sampleRate = 44100,
  })  : _methodBridge = ChannelMethodBridge(),
        _symbolBridge = SymbolEventBridge(),
        _telemetryBridge = TelemetryEventBridge();

  @override
  final ChannelId id = ChannelId.acoustic;

  final int freq0Hz;
  final int freq1Hz;
  final int symbolDurationMs;
  final int sampleRate;

  final ChannelMethodBridge _methodBridge;
  final SymbolEventBridge _symbolBridge;
  final TelemetryEventBridge _telemetryBridge;

  Map<String, dynamic> get _baseConfig => {
        'freq0Hz': freq0Hz,
        'freq1Hz': freq1Hz,
        'symbolDurationMs': symbolDurationMs,
        'sampleRate': sampleRate,
      };

  @override
  Future<ChannelCapabilities> initialize() async {
    try {
      await _methodBridge.initialize(id);
      return const ChannelCapabilities(hardwareAvailable: true);
    } on PlatformException catch (e) {
      return ChannelCapabilities(hardwareAvailable: false, unavailableReason: e.message);
    }
  }

  @override
  Future<Map<String, double>> calibrate() => _methodBridge.calibrate(id, args: _baseConfig);

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) {
    return _methodBridge.startTransmit(id, {..._baseConfig, ...config, 'bits': bits});
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    final controller = StreamController<ReceivedSymbol>();
    final subscription = _symbolBridge.listen(id).listen(controller.add, onError: controller.addError);
    unawaited(_methodBridge.startReceive(id, {..._baseConfig, ...config}));
    controller.onCancel = subscription.cancel;
    return controller.stream;
  }

  @override
  Stream<ChannelMetrics> get metrics => _telemetryBridge.listen(id);

  @override
  Future<void> stop() => _methodBridge.stop(id);
}
