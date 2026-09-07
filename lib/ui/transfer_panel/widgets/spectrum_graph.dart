import 'package:flutter/material.dart';

import '../../../theme/phyra_colors.dart';
import '../../../theme/phyra_text_styles.dart';

class SpectrumGraph extends StatelessWidget {
  const SpectrumGraph({super.key, required this.bins, required this.binFreqsHz});

  final List<double> bins;
  final List<int> binFreqsHz;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequensy', style: PhyraTextStyles.telemetryLabel),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(painter: _SpectrumPainter(bins)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (binFreqsHz.isNotEmpty) Text('${binFreqsHz.first} Hz', style: PhyraTextStyles.telemetryLabel),
            if (binFreqsHz.length > 1) Text('${binFreqsHz.last} Hz', style: PhyraTextStyles.telemetryLabel),
          ],
        ),
      ],
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter(this.bins);

  final List<double> bins;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = PhyraColors.darkGray
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    if (bins.isEmpty) return;
    final barPaint = Paint()..color = PhyraColors.white;
    final barWidth = size.width / bins.length;
    for (var i = 0; i < bins.length; i++) {
      final magnitude = bins[i].clamp(0.0, 1.0);
      final barHeight = magnitude * size.height;
      final left = i * barWidth + barWidth * 0.15;
      final right = (i + 1) * barWidth - barWidth * 0.15;
      canvas.drawRect(
        Rect.fromLTRB(left, size.height - barHeight, right, size.height),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) => oldDelegate.bins != bins;
}
