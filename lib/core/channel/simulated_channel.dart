import 'dart:async';
import 'dart:math';

import 'channel_capabilities.dart';
import 'channel_id.dart';
import 'channel_metrics.dart';
import 'physical_channel.dart';
import 'received_symbol.dart';

class SimulatedChannel implements PhysicalChannel {
  SimulatedChannel({
    required this.id,
    this.symbolDuration = const Duration(milliseconds: 15),
    this.bitErrorRate = 0.0,
    this.calibrationLatency = const Duration(milliseconds: 300),
  });

  @override
  final ChannelId id;

  final Duration symbolDuration;
  final double bitErrorRate;
  final Duration calibrationLatency;

  final Random _random = Random();
  final StreamController<ChannelMetrics> _metricsController = StreamController.broadcast();
  StreamController<ReceivedSymbol>? _receiveController;
  bool _stopRequested = false;

  @override
  Stream<ChannelMetrics> get metrics => _metricsController.stream;

  @override
  Future<ChannelCapabilities> initialize() async =>
      const ChannelCapabilities(hardwareAvailable: true);

  @override
  Future<Map<String, double>> calibrate() async {
    await Future.delayed(calibrationLatency);
    return {'noiseFloorDb0': -60, 'noiseFloorDb1': -60};
  }

  @override
  Future<void> startTransmit(List<int> bits, {required Map<String, dynamic> config}) async {
    _stopRequested = false;
    for (var i = 0; i < bits.length; i++) {
      if (_stopRequested) return;
      await Future.delayed(symbolDuration);
      final bit = bits[i];
      final delivered = _random.nextDouble() < bitErrorRate ? 1 - bit : bit;
      final confidence = delivered == bit ? 0.9 + _random.nextDouble() * 0.1 : 0.4 + _random.nextDouble() * 0.2;

      _receiveController?.add(ReceivedSymbol(
        bit: delivered,
        confidence: confidence,
        timestampUs: DateTime.now().microsecondsSinceEpoch,
      ));
      _metricsController.add(AcousticMetrics(
        spectrumBins: [delivered == 0 ? confidence : 1 - confidence, delivered == 1 ? confidence : 1 - confidence],
        binFreqsHz: const [4000, 6000],
        signalLevel: confidence,
        detectedSymbol: delivered,
        confidence: confidence,
        state: AcousticLinkState.locked,
      ));
    }
  }

  @override
  Stream<ReceivedSymbol> startReceive({required Map<String, dynamic> config}) {
    _receiveController?.close();
    _receiveController = StreamController<ReceivedSymbol>.broadcast();
    return _receiveController!.stream;
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    await _receiveController?.close();
    _receiveController = null;
  }
}
