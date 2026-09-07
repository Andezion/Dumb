import 'package:flutter/material.dart';

import '../../../theme/phyra_colors.dart';
import '../../../theme/phyra_text_styles.dart';
import '../../common/phyra_panel.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return PhyraPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: PhyraTextStyles.telemetryLabel),
          const SizedBox(height: 6),
          Text(
            value,
            style: PhyraTextStyles.telemetryValue.copyWith(color: valueColor ?? PhyraColors.white),
          ),
        ],
      ),
    );
  }
}
