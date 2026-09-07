import 'package:flutter/material.dart';

import '../../../theme/phyra_colors.dart';
import '../../../theme/phyra_text_styles.dart';

class SignalMeter extends StatelessWidget {
  const SignalMeter({super.key, required this.level, this.segmentCount = 24});

  final double level;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    final filled = (level.clamp(0.0, 1.0) * segmentCount).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Signal', style: PhyraTextStyles.telemetryLabel),
        const SizedBox(height: 6),
        Row(
          children: List.generate(segmentCount, (i) {
            return Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: i < filled ? PhyraColors.white : PhyraColors.darkGray,
              ),
            );
          }),
        ),
      ],
    );
  }
}
