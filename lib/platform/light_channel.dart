import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/channel/channel_capabilities.dart';
import '../core/channel/channel_id.dart';
import '../core/channel/channel_metrics.dart';
import '../core/channel/physical_channel.dart';
import '../core/channel/received_symbol.dart';
import 'channel_method_bridge.dart';
import 'symbol_event_bridge.dart';
import 'telemetry_event_bridge.dart';

class LightChannel implements PhysicalChannel {
  LightChannel({this.symbolDurationMs = 150})
      : _methodBridge = ChannelMethodBridge(),
        _symbolBridge = SymbolEventBridge(),
        _telemetryBridge = TelemetryEventBridge();

  @override
  final ChannelId id = ChannelId.ambientLight;

  final int symbolDurationMs;

  final ChannelMethodBridge _methodBridge;
  final SymbolEventBridge _symbolBridge;
  final TelemetryEventBridge _telemetryBridge;

  Map<String, dynamic> get _baseConfig => {'symbolDurationMs': symbolDurationMs};

  @override
  Future<ChannelCapabilities> initialize() async {
    debugPrint('[LightChannel] initialize()');
    try {
      await _methodBridge.initialize(id);
      debugPrint('[LightChannel] initialize() OK, hardware available');
      return const ChannelCapabilities(hardwareAvailable: true);
    } on PlatformException catch (e) {
      debugPrint('[LightChannel] initialize() FAILED: ${e.message}');
      return ChannelCapabilities(hardwareAvailable: false, unavailableReason: e.message);
    }
  }

  @override
  Future<Map<String, double>> calibrate() {
    debugPrint('[LightChannel] calibrate()');
    return _methodBridge.calibrate(id, args: _baseConfig);
  }

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) {
    debugPrint('[LightChannel] startTransmit() ${bits.length} bit(s)');
    return _methodBridge.startTransmit(id, {..._baseConfig, ...config, 'bits': bits});
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    debugPrint('[LightChannel] startReceive()');
    final controller = StreamController<ReceivedSymbol>();
    final subscription = _symbolBridge.listen(id).listen(controller.add, onError: controller.addError);
    unawaited(_methodBridge.startReceive(id, {..._baseConfig, ...config}));
    controller.onCancel = subscription.cancel;
    return controller.stream;
  }

  @override
  Stream<ChannelMetrics> get metrics => _telemetryBridge.listen(id);

  @override
  Future<void> stop() {
    debugPrint('[LightChannel] stop()');
    return _methodBridge.stop(id);
  }
}
