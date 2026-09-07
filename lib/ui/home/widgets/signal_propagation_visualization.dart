import 'package:flutter/material.dart';

import '../../../theme/phyra_colors.dart';

class SignalPropagationVisualization extends StatefulWidget {
  const SignalPropagationVisualization({super.key});

  @override
  State<SignalPropagationVisualization> createState() => _SignalPropagationVisualizationState();
}

class _SignalPropagationVisualizationState extends State<SignalPropagationVisualization>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SignalPainter(_controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  _SignalPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = PhyraColors.darkGray
      ..strokeWidth = 1;
    final nodePaint = Paint()..color = PhyraColors.lightGray;
    final pulsePaint = Paint()..color = PhyraColors.white;

    final y = size.height / 2;
    const nodeRadius = 4.0;
    final leftX = nodeRadius + 2;
    final rightX = size.width - nodeRadius - 2;

    canvas.drawLine(Offset(leftX, y), Offset(rightX, y), linePaint);
    canvas.drawCircle(Offset(leftX, y), nodeRadius, nodePaint);
    canvas.drawCircle(Offset(rightX, y), nodeRadius, nodePaint);

    final pulseX = leftX + (rightX - leftX) * progress;
    canvas.drawCircle(Offset(pulseX, y), 3, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _SignalPainter oldDelegate) => oldDelegate.progress != progress;
}
