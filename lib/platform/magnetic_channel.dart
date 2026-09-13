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

class MagneticChannel implements PhysicalChannel {
  MagneticChannel({this.toneHz = 40, this.symbolDurationMs = 150})
      : _methodBridge = ChannelMethodBridge(),
        _symbolBridge = SymbolEventBridge(),
        _telemetryBridge = TelemetryEventBridge();

  @override
  final ChannelId id = ChannelId.magnetic;

  final int toneHz;
  final int symbolDurationMs;

  final ChannelMethodBridge _methodBridge;
  final SymbolEventBridge _symbolBridge;
  final TelemetryEventBridge _telemetryBridge;

  Map<String, dynamic> get _baseConfig => {'toneHz': toneHz, 'symbolDurationMs': symbolDurationMs};

  @override
  Future<ChannelCapabilities> initialize() async {
    debugPrint('[MagneticChannel] initialize()');
    try {
      await _methodBridge.initialize(id);
      debugPrint('[MagneticChannel] initialize() OK, hardware available');
      return const ChannelCapabilities(hardwareAvailable: true);
    } on PlatformException catch (e) {
      debugPrint('[MagneticChannel] initialize() FAILED: ${e.message}');
      return ChannelCapabilities(hardwareAvailable: false, unavailableReason: e.message);
    }
  }

  @override
  Future<Map<String, double>> calibrate() {
    debugPrint('[MagneticChannel] calibrate()');
    return _methodBridge.calibrate(id, args: _baseConfig);
  }

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) {
    debugPrint('[MagneticChannel] startTransmit() ${bits.length} bit(s)');
    return _methodBridge.startTransmit(id, {..._baseConfig, ...config, 'bits': bits});
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    debugPrint('[MagneticChannel] startReceive()');
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
    debugPrint('[MagneticChannel] stop()');
    return _methodBridge.stop(id);
  }
}
