import 'package:flutter/material.dart';

import 'package:qranalyzer/qr_region.dart';

class QrOriginalPainter extends CustomPainter {
  final List<List<bool>> matrix;
  final List<List<QrRegion>> regionMap;

  QrOriginalPainter(this.matrix, this.regionMap);

  @override
  void paint(Canvas canvas, Size size) {
    final paintWhite = Paint()..color = Colors.white;
    final paintBlack = Paint()..color = Colors.black;

    final n = matrix.length;
    final cell = size.width / n;

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);

        Paint bg = paintBlack;
        switch (regionMap[y][x]) {
          case QrRegion.data:
          case QrRegion.ecc:
          case QrRegion.finder:
          case QrRegion.timing:
          case QrRegion.format:
          case QrRegion.version:
          case QrRegion.alignment:
          case QrRegion.unused:
            bg = paintWhite;
        }

        canvas.drawRect(rect, matrix[y][x] ? paintBlack : bg);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
