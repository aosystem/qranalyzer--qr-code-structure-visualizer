import 'package:flutter/material.dart';

import 'package:qranalyzer/is_masked.dart';

class QrMaskPainter extends CustomPainter {
  final int maskPattern;
  final int size;

  QrMaskPainter(this.maskPattern, this.size);

  @override
  void paint(Canvas canvas, Size s) {
    final cell = s.width / size;
    final paintMask = Paint()..color = Colors.grey.withValues(alpha: 0.5);

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (isMasked(maskPattern, x, y)) {
          final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
          canvas.drawRect(rect, paintMask);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
