import 'package:flutter/material.dart';

import '../../../theme/phyra_colors.dart';

class OpticalGridView extends StatelessWidget {
  const OpticalGridView({super.key, required this.cells, required this.rows, required this.cols});

  final List<bool> cells;
  final int rows;
  final int cols;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: cols / rows,
      child: CustomPaint(
        painter: _OpticalGridPainter(cells: cells, rows: rows, cols: cols),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OpticalGridPainter extends CustomPainter {
  _OpticalGridPainter({required this.cells, required this.rows, required this.cols});

  final List<bool> cells;
  final int rows;
  final int cols;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = PhyraColors.black);
    if (cells.length != rows * cols) return;

    final onPaint = Paint()..color = PhyraColors.white;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (!cells[row * cols + col]) continue;
        canvas.drawRect(
          Rect.fromLTWH(col * cellWidth, row * cellHeight, cellWidth, cellHeight),
          onPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OpticalGridPainter oldDelegate) =>
      oldDelegate.cells != cells || oldDelegate.rows != rows || oldDelegate.cols != cols;
}

class OpticalViewfinderOverlay extends StatelessWidget {
  const OpticalViewfinderOverlay({super.key, required this.cols, required this.rows});

  final int cols;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ViewfinderPainter(cols: cols, rows: rows), child: const SizedBox.expand());
  }
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({required this.cols, required this.rows});

  final int cols;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    var cropWidth = size.width;
    var cropHeight = cropWidth * rows / cols;
    if (cropHeight > size.height) {
      cropHeight = size.height;
      cropWidth = cropHeight * cols / rows;
    }
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: cropWidth,
      height: cropHeight,
    );
    final paint = Paint()
      ..color = PhyraColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.cols != cols || oldDelegate.rows != rows;
}
