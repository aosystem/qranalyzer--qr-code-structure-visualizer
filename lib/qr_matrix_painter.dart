import 'package:flutter/material.dart';

import 'package:qranalyzer/qr_region.dart';

class QrMatrixPainter extends CustomPainter {
  final List<List<bool>> matrix;
  final List<List<QrRegion>> regionMap;

  QrMatrixPainter(this.matrix, this.regionMap);

  @override
  void paint(Canvas canvas, Size size) {
    final paintData = Paint()..color = Colors.blue;
    final paintECC = Paint()..color = Colors.red;
    final paintOther = Paint()..color = Colors.white;
    final paintDark = Paint()..color = Colors.black;
    final paintFinder = Paint()..color = Colors.green;
    final paintTiming = Paint()..color = Colors.yellow;
    final paintFormat = Paint()..color = Colors.purple;
    final paintVersion = Paint()..color = Colors.orange;
    final paintAlignment = Paint()..color = Colors.cyan;

    final n = matrix.length;
    final cell = size.width / n;

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);

        Paint bg;
        switch (regionMap[y][x]) {
          case QrRegion.data:
            bg = paintData;
            break;
          case QrRegion.ecc:
            bg = paintECC;
            break;
          case QrRegion.finder:
            bg = paintFinder;
            break;
          case QrRegion.timing:
            bg = paintTiming;
            break;
          case QrRegion.format:
            bg = paintFormat;
            break;
          case QrRegion.version:
            bg = paintVersion;
            break;
          case QrRegion.alignment:
            bg = paintAlignment;
            break;
          default:
            bg = paintOther;
        }

        canvas.drawRect(rect, matrix[y][x] ? paintDark : bg);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
