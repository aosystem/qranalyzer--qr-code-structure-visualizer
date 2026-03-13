import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qranalyzer/qr_region.dart';

class QrUnmaskedPainter extends CustomPainter {
  final List<List<bool>> matrix;
  final List<List<QrRegion>> regionMap;
  final List<Point<int>> bitOrder;
  final int highlightIndex;
  final int dataBitLimit;

  QrUnmaskedPainter(
      this.matrix,
      this.regionMap,
      this.bitOrder,
      this.highlightIndex,
      this.dataBitLimit,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final int n = matrix.length;
    final double cell = size.width / n;

    final Paint paintNull = Paint()..color = Colors.grey.withValues(alpha: 0.3);
    final Paint paintDark = Paint()..color = Colors.black.withValues(alpha: 0.8);
    final Paint paintLight = Paint()..color = Colors.white.withValues(alpha: 0.8);

    final Paint paintDataHighlight = Paint()..color = Colors.blue;
    final Paint paintEccHighlight = Paint()..color = Colors.red;
    final Paint paintDataPassed = Paint()..color = Colors.blue.withValues(alpha: 0.4);
    final Paint paintEccPassed = Paint()..color = Colors.red.withValues(alpha: 0.4);

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final region = regionMap[y][x];
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        if (region == QrRegion.data || region == QrRegion.ecc) {
          canvas.drawRect(rect, matrix[y][x] ? paintDark : paintLight);
        } else {
          canvas.drawRect(rect, paintNull);
        }
      }
    }

    for (int i = 0; i <= highlightIndex && i < bitOrder.length; i++) {
      final p = bitOrder[i];
      final rect = Rect.fromLTWH(p.x * cell, p.y * cell, cell, cell);

      bool isData = i < dataBitLimit;

      Paint paint;
      if (i == highlightIndex) {
        paint = isData ? paintDataHighlight : paintEccHighlight;
      } else {
        paint = isData ? paintDataPassed : paintEccPassed;
      }

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant QrUnmaskedPainter oldDelegate) =>
      oldDelegate.highlightIndex != highlightIndex || oldDelegate.dataBitLimit != dataBitLimit;
}
