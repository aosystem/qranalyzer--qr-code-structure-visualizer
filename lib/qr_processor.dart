import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/zxing.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/common.dart';

import 'package:qranalyzer/qr_info.dart';
import 'package:qranalyzer/qr_region.dart';
import 'package:qranalyzer/qr_spec.dart';
import 'package:qranalyzer/is_masked.dart';

class QrProcessor {

  static const Map<int, List<int>> _alignmentTable = {
    2: [6, 18],
    3: [6, 22],
    4: [6, 26],
    5: [6, 30],
    6: [6, 34],
    7: [6, 22, 38],
    8: [6, 24, 42],
    9: [6, 26, 46],
    10: [6, 28, 50],
    11: [6, 30, 54],
    12: [6, 32, 58],
    13: [6, 34, 62],
    14: [6, 26, 46, 66],
    15: [6, 26, 48, 70],
    16: [6, 26, 50, 74],
    17: [6, 30, 54, 78],
    18: [6, 30, 56, 82],
    19: [6, 30, 58, 86],
    20: [6, 34, 62, 90],
    21: [6, 28, 50, 72, 94],
    22: [6, 26, 50, 74, 98],
    23: [6, 30, 54, 78, 102],
    24: [6, 28, 54, 80, 106],
    25: [6, 32, 58, 84, 110],
    26: [6, 30, 58, 86, 114],
    27: [6, 34, 62, 90, 118],
    28: [6, 26, 50, 74, 98, 122],
    29: [6, 30, 54, 78, 102, 126],
    30: [6, 26, 52, 78, 104, 130],
    31: [6, 30, 56, 82, 108, 134],
    32: [6, 34, 60, 86, 112, 138],
    33: [6, 30, 58, 86, 114, 142],
    34: [6, 34, 62, 90, 118, 146],
    35: [6, 30, 54, 78, 102, 126, 150],
    36: [6, 24, 50, 76, 102, 128, 154],
    37: [6, 28, 54, 80, 106, 132, 158],
    38: [6, 32, 58, 84, 110, 136, 162],
    39: [6, 26, 54, 82, 110, 138, 166],
    40: [6, 30, 58, 86, 114, 142, 170],
  };

  Future<(List<List<bool>> matrix, QrInfo info)> extractRawPattern(img.Image originalImage) async {
    Object? lastError;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        img.Image processed = _applyPreprocess(originalImage, attempt);
        final Int32List argb = _convertToArgb(processed);
        final source = RGBLuminanceSource(processed.width, processed.height, argb);
        final bitmap = BinaryBitmap(HybridBinarizer(source));

        final detectorResult = Detector(bitmap.blackMatrix).detect();
        final bm = detectorResult.bits;
        final int size = bm.width;

        final matrix = List.generate(
          size, (y) => List.generate(size, (x) => bm.get(x, y)),
        );

        final int raw1 = _readFormatLocation1(matrix);
        final int raw2 = _readFormatLocation2(matrix);
        final formatInfo = FormatInformation.decodeFormatInformation(raw1, raw2);
        if (formatInfo == null) {
        }
        String ecLevel;
        int maskPattern;
        if (formatInfo != null) {
          ecLevel = formatInfo.errorCorrectionLevel.name;
          maskPattern = formatInfo.dataMask.toInt();
        } else {
          final unmasked = raw1 ^ 0x5412;
          final ecBits = (unmasked >> 13) & 0x03;
          ecLevel = ["M", "L", "H", "Q"][ecBits];
          maskPattern = (unmasked >> 10) & 0x07;
        }
        final int version = ((size - 21) ~/ 4) + 1;

        if (version < 1 || version > 40) {
          throw Exception("Invalid version: $version");
        }

        final (int dataCW, int eccCW) = QrSpec.get(version, ecLevel);

        return (matrix, QrInfo(
          version: version,
          ecLevel: ecLevel,
          maskPattern: maskPattern,
          size: size,
          dataCodewords: dataCW,
          eccCodewords: eccCW,
          decodedText: _tryDecodeText(bitmap),
        ));

      } catch (e) {
        lastError = e;
        continue;
      }
    }
    throw lastError ?? Exception("Analysis failed after 3 attempts.");
  }

  img.Image _applyPreprocess(img.Image originalImage, int attempt) {
    switch (attempt) {
      case 0:
        return originalImage;
      case 1:
        var processed = img.contrast(originalImage.clone(), contrast: 1.5);
        return img.convolution(processed, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
      case 2:
        return img.luminanceThreshold(originalImage.clone(), threshold: 0.5);
      default:
        return originalImage;
    }
  }

  List<List<QrRegion>> classifyModules(int version, int dataCW, int eccCW) {
    final size = 21 + 4 * (version - 1);
    final map = List.generate(size, (_) => List.filled(size, QrRegion.unused));

    _markFinderPatterns(map);
    _markTimingPatterns(map);
    _markFormatInfo(map);
    _markVersionInfo(map, version);
    _markAlignmentPatterns(map, version);
    _markDarkModule(map, version);

    int totalBits = (dataCW + eccCW) * 8;
    int dataBits = dataCW * 8;
    int bitIndex = 0;
    int col = size - 1;
    bool upward = true;

    while (col > 0) {
      if (col == 6) col--;
      for (int i = 0; i < size; i++) {
        int row = upward ? (size - 1 - i) : i;
        for (int c = col; c >= col - 1; c--) {
          if (map[row][c] == QrRegion.unused) {
            if (bitIndex < totalBits) {
              map[row][c] = (bitIndex < dataBits) ? QrRegion.data : QrRegion.ecc;
              bitIndex++;
            }
          }
        }
      }
      col -= 2;
      upward = !upward;
    }
    return map;
  }

  List<List<bool>> unmaskMatrix(List<List<bool>> matrix, List<List<QrRegion>> regionMap, int mask) {
    final n = matrix.length;
    return List.generate(n, (y) => List.generate(n, (x) {
      final isData = regionMap[y][x] == QrRegion.data || regionMap[y][x] == QrRegion.ecc;
      if (!isData) return matrix[y][x];
      return isMasked(mask, x, y) ? !matrix[y][x] : matrix[y][x];
    }));
  }

  List<Point<int>> getBitOrder(int version, List<List<QrRegion>> regionMap) {
    final size = regionMap.length;
    List<Point<int>> order = [];
    int col = size - 1;
    bool upward = true;

    while (col > 0) {
      if (col == 6) col--;
      for (int i = 0; i < size; i++) {
        int row = upward ? (size - 1 - i) : i;
        for (int c = col; c >= col - 1; c--) {
          if (regionMap[row][c] == QrRegion.data || regionMap[row][c] == QrRegion.ecc) {
            order.add(Point(c, row));
          }
        }
      }
      col -= 2;
      upward = !upward;
    }
    return order;
  }

  void _markAlignmentPatterns(List<List<QrRegion>> map, int version) {
    final positions = _alignmentTable[version];
    if (positions == null || positions.isEmpty) {
      return;
    }

    final n = map.length;

    for (final cy in positions) {
      for (final cx in positions) {
        if ((cx <= 8 && cy <= 8) ||
            (cx >= n - 9 && cy <= 8) ||
            (cx <= 8 && cy >= n - 9)) {
          continue;
        }

        for (int dy = -2; dy <= 2; dy++) {
          for (int dx = -2; dx <= 2; dx++) {
            final y = cy + dy;
            final x = cx + dx;
            if (x >= 0 && x < n && y >= 0 && y < n) {
              map[y][x] = QrRegion.alignment;
            }
          }
        }
      }
    }
  }

  void _markVersionInfo(List<List<QrRegion>> map, int version) {
    if (version < 7) return;
    final size = map.length;
    for (int x = 0; x < 6; x++) {
      for (int y = size - 11; y < size - 8; y++) {
        map[y][x] = QrRegion.version;
      }
    }
    for (int y = 0; y < 6; y++) {
      for (int x = size - 11; x < size - 8; x++) {
        map[y][x] = QrRegion.version;
      }
    }
  }

  void _markDarkModule(List<List<QrRegion>> map, int version) {
    final size = map.length;
    map[size - 8][8] = QrRegion.format;
  }

  Int32List _convertToArgb(img.Image image) {
    final length = image.width * image.height;
    final result = Int32List(length);
    int i = 0;
    for (final pixel in image) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      result[i++] = (0xFF << 24) | (r << 16) | (g << 8) | b;
    }
    return result;
  }

  int _readFormatLocation1(List<List<bool>> m) {
    final List<List<int>> pixelCoordinates = [
      [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], [7, 8], [8, 8],
      [8, 7], [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0]
    ];
    int v = 0;
    for (final c in pixelCoordinates) {
      v = (v << 1) | (m[c[0]][c[1]] ? 1 : 0);
    }
    return v;
  }

  int _readFormatLocation2(List<List<bool>> m) {
    final int size = m.length;
    final List<List<int>> pixelCoordinates = [
      [size - 1, 8], [size - 2, 8], [size - 3, 8], [size - 4, 8],
      [size - 5, 8], [size - 6, 8], [size - 7, 8],
      [8, size - 8], [8, size - 7], [8, size - 6], [8, size - 5],
      [8, size - 4], [8, size - 3], [8, size - 2], [8, size - 1]
    ];
    int v = 0;
    for (final c in pixelCoordinates) {
      v = (v << 1) | (m[c[0]][c[1]] ? 1 : 0);
    }
    return v;
  }

  String? _tryDecodeText(BinaryBitmap bitmap) {
    try {
      return QRCodeReader().decode(bitmap).text;
    } catch (_) {
      return null;
    }
  }

  void _markFinderPatterns(List<List<QrRegion>> map) {
    final size = map.length;
    void mark(int ox, int oy) {
      for (int y = oy; y < oy + 7; y++) {
        for (int x = ox; x < ox + 7; x++) { map[y][x] = QrRegion.finder; }
      }
    }
    mark(0, 0);
    mark(size - 7, 0);
    mark(0, size - 7);
  }

  void _markTimingPatterns(List<List<QrRegion>> map) {
    final size = map.length;
    for (int i = 0; i < size; i++) {
      map[6][i] = QrRegion.timing;
      map[i][6] = QrRegion.timing;
    }
  }

  void _markFormatInfo(List<List<QrRegion>> map) {
    final size = map.length;
    for (int i = 0; i <= 5; i++) {
      map[8][i] = QrRegion.format;
    }
    map[8][7] = QrRegion.format;
    map[8][8] = QrRegion.format;
    for (int i = size - 1; i >= size - 7; i--) {
      map[i][8] = QrRegion.format;
    }
  }

}