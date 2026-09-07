import 'package:flutter/material.dart';

import 'metric_tile.dart';

class PacketCounterTile extends StatelessWidget {
  const PacketCounterTile({super.key, required this.count, required this.total});

  final int count;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return MetricTile(
      label: 'Packets',
      value: total != null ? '$count / $total' : '$count',
    );
  }
}
