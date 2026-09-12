import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/channel/channel_id.dart';
import '../core/channel/received_symbol.dart';

class SymbolEventBridge {
  SymbolEventBridge() : _eventChannel = const EventChannel('phyra/symbols');

  final EventChannel _eventChannel;

  Stream<ReceivedSymbol> listen(ChannelId id) {
    debugPrint('[SymbolEventBridge] listen(${id.name}) subscribing to native event channel');
    var symbolCount = 0;
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => (event as Map)['channelId'] == id.name)
        .map((event) {
      final map = event as Map;
      symbolCount++;
      if (symbolCount % 50 == 0) {
        debugPrint('[SymbolEventBridge] ${id.name} received $symbolCount symbol(s) so far');
      }
      return ReceivedSymbol(
        bit: map['bit'] as int,
        confidence: (map['confidence'] as num).toDouble(),
        timestampUs: map['timestampUs'] as int,
      );
    });
  }
}
