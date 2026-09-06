import 'package:flutter/services.dart';

import '../core/channel/channel_id.dart';

class ChannelMethodBridge {
  ChannelMethodBridge() : _channel = const MethodChannel('phyra/control');

  final MethodChannel _channel;

  Future<Map<String, bool>> getCapabilities() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getCapabilities');
    return result!.map((key, value) => MapEntry(key, value as bool));
  }

  Future<void> initialize(ChannelId id) =>
      _channel.invokeMethod<void>('initialize', {'channelId': id.name});

  Future<Map<String, double>> calibrate(ChannelId id, {Map<String, dynamic> args = const {}}) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'calibrate',
      {'channelId': id.name, ...args},
    );
    return result!.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<void> startTransmit(ChannelId id, Map<String, dynamic> args) =>
      _channel.invokeMethod<void>('startTransmit', {'channelId': id.name, ...args});

  Future<void> startReceive(ChannelId id, Map<String, dynamic> args) =>
      _channel.invokeMethod<void>('startReceive', {'channelId': id.name, ...args});

  Future<void> stop(ChannelId id) =>
      _channel.invokeMethod<void>('stop', {'channelId': id.name});
}
