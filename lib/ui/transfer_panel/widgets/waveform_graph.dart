import 'package:flutter/material.dart';

import '../../../theme/phyra_colors.dart';
import '../../../theme/phyra_text_styles.dart';

class WaveformGraph extends StatelessWidget {
  const WaveformGraph({super.key, required this.label, required this.samples, required this.maxValue});

  final String label;
  final List<double> samples;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PhyraTextStyles.telemetryLabel),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(painter: _WaveformPainter(samples, maxValue)),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.samples, this.maxValue);

  final List<double> samples;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = PhyraColors.darkGray
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    if (samples.isEmpty) return;
    final linePaint = Paint()
      ..color = PhyraColors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final stepX = samples.length > 1 ? size.width / (samples.length - 1) : size.width;
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final normalized = (samples[i] / safeMax).clamp(0.0, 1.0);
      final x = i * stepX;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.maxValue != maxValue;
}
