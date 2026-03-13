import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import 'package:qranalyzer/instruction_panel.dart';
import 'package:qranalyzer/qr_info.dart';
import 'package:qranalyzer/qr_matrix_painter.dart';
import 'package:qranalyzer/parse_locale_tag.dart';
import 'package:qranalyzer/qr_original_painter.dart';
import 'package:qranalyzer/setting_page.dart';
import 'package:qranalyzer/theme_color.dart';
import 'package:qranalyzer/theme_mode_number.dart';
import 'package:qranalyzer/ad_manager.dart';
import 'package:qranalyzer/loading_screen.dart';
import 'package:qranalyzer/model.dart';
import 'package:qranalyzer/main.dart';
import 'package:qranalyzer/ad_banner_widget.dart';
import 'package:qranalyzer/qr_region.dart';
import 'package:qranalyzer/legend_panel.dart';
import 'package:qranalyzer/qr_unmasked_painter.dart';
import 'package:qranalyzer/qr_mask_painter.dart';
import 'package:qranalyzer/camera_page.dart';
import 'package:qranalyzer/info_panel.dart';
import 'package:qranalyzer/image_select_page.dart';
import 'package:qranalyzer/qr_processor.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  //
  final QrProcessor _processor = QrProcessor();
  bool _isProcessing = false;
  List<List<bool>>? _matrix;
  String? _error;
  QrInfo? _info;
  List<List<QrRegion>>? _regionMap;
  List<List<bool>>? _unmasked;
  int? _maskPattern;
  int _currentBitIndex = 0;
  List<Point<int>> _bitOrder = [];

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze(XFile photo) async {
    setState(() {
      _isProcessing = true;
      _matrix = null;
      _info = null;
      _regionMap = null;
      _unmasked = null;
      _maskPattern = null;
      _error = null;
    });
    try {
      final bytes = await photo.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception("Decode failed");
      }
      if (image.width > 1000) {
        image = img.copyResize(image, width: 1000, interpolation: img.Interpolation.nearest);
      }
      final (matrix, info) = await _processor.extractRawPattern(image);
      final regionMap = _processor.classifyModules(info.version, info.dataCodewords, info.eccCodewords);
      final unmasked = _processor.unmaskMatrix(matrix, regionMap, info.maskPattern);
      if (!mounted) {
        return;
      }
      setState(() {
        _matrix = matrix;
        _info = info;
        _regionMap = regionMap;
        _unmasked = unmasked;
        _maskPattern = info.maskPattern;
        _bitOrder = _processor.getBitOrder(info.version, regionMap);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        final String errorStr = e.toString();
        if (errorStr.contains('NotFoundException')) {
          _error = 'No QR code found.';
        } else if (errorStr.contains('Format not found')) {
          _error = 'QR code detected, but data reading failed.';
        } else {
          _error = 'Analysis failed.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _openSetting() async {
    final updatedSettings = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingPage(),
      ),
    );
    if (updatedSettings != null) {
      if (mounted) {
        final mainState = context.findAncestorStateOfType<MainAppState>();
        if (mainState != null) {
          mainState
            ..locale = parseLocaleTag(Model.languageCode)
            ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
            ..setState(() {});
        }
      }
      if (mounted) {
        setState(() {
          _isFirst = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(context: context);
    }
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      body: Stack(children:[
        _buildBackground(),
        SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildButton(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _buildMatrixWidget(),
                      _buildQrUnmaskedPainterAndSeekBar(),
                      InfoPanel(info: _info),
                      InstructionPanel(),
                    ]
                  )
                )
              )
            ]
          )
        )
      ]),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager)
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_themeColor.mainBack2Color, _themeColor.mainBackColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: DecorationImage(
          image: AssetImage('assets/image/tile.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text('QR Analyzer', style: t.titleSmall?.copyWith(color: _themeColor.mainForeColor)),
          const Spacer(),
          IconButton(
            onPressed: _openSetting,
            icon: Icon(Icons.settings,color: _themeColor.mainForeColor.withValues(alpha: 0.6)),
          ),
        ],
      )
    );
  }

  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                side: const BorderSide(color: Colors.grey, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: _isProcessing ? null : () async {
                final XFile? photo = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraPage()),
                );
                if (photo != null) _captureAndAnalyze(photo);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt),
                  const SizedBox(width: 8),
                  Text(_isProcessing ? 'Analyzing...' : 'Capture\nQR code'),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                side: const BorderSide(color: Colors.grey, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: _isProcessing ? null : () async {
                final XFile? photo = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImageSelectPage()),
                );
                if (photo != null) _captureAndAnalyze(photo);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_search),
                  const SizedBox(width: 8),
                  Text(_isProcessing ? 'Analyzing...' : 'Choose\nimage'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixWidget() {
    return Column(children: [
      if (_matrix != null) ...[
        _buildQrOriginalPainter(),
        const LegendPanel(),
        _buildQrMatrixPainter(),
        _buildQrMaskPainter(),
      ]
      else if (_error != null)
        Container(
          margin: const EdgeInsets.only(left: 12, right: 12),
          child: Text(_error!),
        )
      else
        const SizedBox.shrink()
    ]);
  }

  Widget _buildQrOriginalPainter() {
    if (_matrix == null || _regionMap == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return CustomPaint(
              size: size,
              painter: QrOriginalPainter(
                _matrix!,
                _regionMap!,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQrMatrixPainter() {
    if (_matrix == null || _regionMap == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return CustomPaint(
              size: size,
              painter: QrMatrixPainter(
                _matrix!,
                _regionMap!,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQrMaskPainter() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return CustomPaint(
              size: size,
              painter: QrMaskPainter(
                _maskPattern!,
                _matrix!.length,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQrUnmaskedPainterAndSeekBar() {
    if (_unmasked == null) {
      return const SizedBox.shrink();
    }
    return Column(children:[
      _buildQrUnmaskedPainter(),
      _buildSeekBar()
    ]);
  }

  Widget _buildQrUnmaskedPainter() {
    if (_unmasked == null || _regionMap == null || _bitOrder.isEmpty || _info == null) {
      return const SizedBox.shrink();
    }
    final int dataBitLimit = _info!.dataCodewords * 8;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return CustomPaint(
              size: size,
              painter: QrUnmaskedPainter(
                _unmasked!,
                _regionMap!,
                _bitOrder,
                _currentBitIndex,
                dataBitLimit,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeekBar() {
    if (_bitOrder.isEmpty || _info == null || _unmasked == null) {
      return const SizedBox.shrink();
    }
    final int dataBitLimit = _info!.dataCodewords * 8;
    final bool isDataRegion = _currentBitIndex < dataBitLimit;
    final currentPoint = _bitOrder[_currentBitIndex];
    final Color regionColor = isDataRegion ? Colors.blue : Colors.red;
    final bool isDark = _unmasked![currentPoint.y][currentPoint.x];
    final String bitValue = isDark ? "1" : "0";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(
                    "(${currentPoint.x},${currentPoint.y})",
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      "Bit:$bitValue",
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: regionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: regionColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  isDataRegion ? "DATA" : "ECC",
                  style: TextStyle(color: regionColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              Text(
                "Index:$_currentBitIndex",
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
            ),
            child: Slider(
              value: _currentBitIndex.toDouble(),
              min: 0,
              max: (_bitOrder.length - 1).toDouble(),
              onChanged: (v) => setState(() => _currentBitIndex = v.toInt()),
            ),
          ),
        ],
      ),
    );
  }
}
