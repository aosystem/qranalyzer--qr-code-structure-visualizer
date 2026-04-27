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

    final Paint paintDark = Paint()..color = Colors.black.withValues(alpha: 0.8);
    final Paint paintLight = Paint()..color = Colors.white.withValues(alpha: 0.8);

    final Paint paintFinder = Paint()..color = Colors.green.withValues(alpha: 0.4);
    final Paint paintTiming = Paint()..color = Colors.orange.withValues(alpha: 0.4);
    final Paint paintAlignment = Paint()..color = Colors.purple.withValues(alpha: 0.4);
    final Paint paintVersionFormat = Paint()..color = Colors.teal.withValues(alpha: 0.4);

    final Paint paintUnused = Paint()..color = Colors.grey.withValues(alpha: 0.2);

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
          Paint p;
          switch (region) {
            case QrRegion.finder:
              p = paintFinder;
              break;
            case QrRegion.timing:
              p = paintTiming;
              break;
            case QrRegion.alignment:
              p = paintAlignment;
              break;
            case QrRegion.version:
            case QrRegion.format:
              p = paintVersionFormat;
              break;
            case QrRegion.unused:
            default:
              p = paintUnused;
              break;
          }
          canvas.drawRect(rect, p);
        }
      }
    }

    for (int i = 0; i <= highlightIndex && i < bitOrder.length; i++) {
      final p = bitOrder[i];
      final rect = Rect.fromLTWH(p.x * cell, p.y * cell, cell, cell);

      bool isData = i < dataBitLimit;

      Paint highlightPaint;
      if (i == highlightIndex) {
        highlightPaint = isData ? paintDataHighlight : paintEccHighlight;
      } else {
        highlightPaint = isData ? paintDataPassed : paintEccPassed;
      }
      canvas.drawRect(rect, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant QrUnmaskedPainter oldDelegate) =>
    oldDelegate.highlightIndex != highlightIndex ||
    oldDelegate.dataBitLimit != dataBitLimit ||
    oldDelegate.matrix != matrix;
}
