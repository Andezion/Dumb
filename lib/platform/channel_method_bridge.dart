import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/channel/channel_id.dart';

class ChannelMethodBridge {
  ChannelMethodBridge() : _channel = const MethodChannel('phyra/control');

  final MethodChannel _channel;

  Future<Map<String, bool>> getCapabilities() async {
    debugPrint('[ChannelMethodBridge] invokeMethod(getCapabilities)');
    final result = await _channel.invokeMapMethod<String, dynamic>('getCapabilities');
    debugPrint('[ChannelMethodBridge] getCapabilities() -> $result');
    return result!.map((key, value) => MapEntry(key, value as bool));
  }

  Future<void> initialize(ChannelId id) {
    debugPrint('[ChannelMethodBridge] invokeMethod(initialize, channelId=${id.name})');
    return _channel.invokeMethod<void>('initialize', {'channelId': id.name});
  }

  Future<Map<String, double>> calibrate(ChannelId id, {Map<String, dynamic> args = const {}}) async {
    debugPrint('[ChannelMethodBridge] invokeMethod(calibrate, channelId=${id.name})');
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'calibrate',
      {'channelId': id.name, ...args},
    );
    debugPrint('[ChannelMethodBridge] calibrate() -> $result');
    return result!.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<void> startTransmit(ChannelId id, Map<String, dynamic> args) {
    debugPrint('[ChannelMethodBridge] invokeMethod(startTransmit, channelId=${id.name})');
    return _channel.invokeMethod<void>('startTransmit', {'channelId': id.name, ...args});
  }

  Future<void> startReceive(ChannelId id, Map<String, dynamic> args) {
    debugPrint('[ChannelMethodBridge] invokeMethod(startReceive, channelId=${id.name})');
    return _channel.invokeMethod<void>('startReceive', {'channelId': id.name, ...args});
  }

  Future<void> stop(ChannelId id) {
    debugPrint('[ChannelMethodBridge] invokeMethod(stop, channelId=${id.name})');
    return _channel.invokeMethod<void>('stop', {'channelId': id.name});
  }
}
