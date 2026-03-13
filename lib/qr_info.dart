class QrInfo {
  final int version;
  final String ecLevel;
  final int maskPattern;
  final int size;
  final int dataCodewords;
  final int eccCodewords;
  final String? decodedText;

  QrInfo({
    required this.version,
    required this.ecLevel,
    required this.maskPattern,
    required this.size,
    required this.dataCodewords,
    required this.eccCodewords,
    required this.decodedText,
  });
}
