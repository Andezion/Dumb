import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/channel/channel_id.dart';
import '../core/channel/channel_metrics.dart';

class TelemetryEventBridge {
  TelemetryEventBridge() : _eventChannel = const EventChannel('phyra/telemetry');

  final EventChannel _eventChannel;

  Stream<ChannelMetrics> listen(ChannelId id) {
    debugPrint('[TelemetryEventBridge] listen(${id.name}) subscribing to native event channel');
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => (event as Map)['channelId'] == id.name)
        .map(_toMetrics);
  }

  ChannelMetrics _toMetrics(dynamic event) {
    final map = event as Map;
    switch (map['kind'] as String) {
      case 'acoustic':
        return AcousticMetrics(
          spectrumBins: (map['spectrumBins'] as List).map((e) => (e as num).toDouble()).toList(),
          binFreqsHz: (map['binFreqsHz'] as List).map((e) => e as int).toList(),
          signalLevel: (map['signalLevel'] as num).toDouble(),
          detectedSymbol: map['detectedSymbol'] as int?,
          confidence: (map['confidence'] as num).toDouble(),
          state: AcousticLinkState.values.byName(map['state'] as String),
        );
      case 'mechanical':
        return MechanicalMetrics(
          accelerationMagnitude: (map['accelerationMagnitude'] as num).toDouble(),
          thresholdMagnitude: (map['thresholdMagnitude'] as num).toDouble(),
          detectedSymbol: map['detectedSymbol'] as int?,
          confidence: (map['confidence'] as num).toDouble(),
          state: MechanicalLinkState.values.byName(map['state'] as String),
        );
      case 'magnetic':
        return MagneticMetrics(
          fieldMagnitudeMicroTesla: (map['fieldMagnitudeMicroTesla'] as num).toDouble(),
          thresholdMicroTesla: (map['thresholdMicroTesla'] as num).toDouble(),
          detectedSymbol: map['detectedSymbol'] as int?,
          confidence: (map['confidence'] as num).toDouble(),
          state: MagneticLinkState.values.byName(map['state'] as String),
        );
      case 'light':
        return LightMetrics(
          luxLevel: (map['luxLevel'] as num).toDouble(),
          thresholdLux: (map['thresholdLux'] as num).toDouble(),
          detectedSymbol: map['detectedSymbol'] as int?,
          confidence: (map['confidence'] as num).toDouble(),
          state: LightLinkState.values.byName(map['state'] as String),
        );
      default:
        debugPrint('[TelemetryEventBridge] ERROR: unknown telemetry kind: ${map['kind']}');
        throw StateError('Unknown telemetry kind: ${map['kind']}');
    }
  }
}
