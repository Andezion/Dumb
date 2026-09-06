import 'package:flutter/services.dart';

import '../core/channel/channel_id.dart';
import '../core/channel/received_symbol.dart';

class SymbolEventBridge {
  SymbolEventBridge() : _eventChannel = const EventChannel('phyra/symbols');

  final EventChannel _eventChannel;

  Stream<ReceivedSymbol> listen(ChannelId id) {
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => (event as Map)['channelId'] == id.name)
        .map((event) {
      final map = event as Map;
      return ReceivedSymbol(
        bit: map['bit'] as int,
        confidence: (map['confidence'] as num).toDouble(),
        timestampUs: map['timestampUs'] as int,
      );
    });
  }
}
