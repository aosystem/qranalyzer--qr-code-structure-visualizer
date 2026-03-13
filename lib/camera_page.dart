import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _isReady = false;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _maxZoom = await controller.getMaxZoomLevel();
      _minZoom = await controller.getMinZoomLevel();
      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (e) {
      debugPrint("カメラ初期化エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _isReady
          ? GestureDetector(
        onScaleStart: (details) {
          _baseZoom = _currentZoom;
        },
        onScaleUpdate: (details) async {
          if (_controller == null) return;

          final newZoom = (_baseZoom * details.scale)
              .clamp(_minZoom, _maxZoom);

          await _controller!.setZoomLevel(newZoom);
          setState(() {
            _currentZoom = newZoom;
          });
        },
        child: CameraPreview(_controller!),
      )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _isReady
          ? FloatingActionButton(
        onPressed: _takePhoto,
        child: const Icon(Icons.camera_alt),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await _controller!.takePicture();
      Navigator.pop(context, file);
    } catch (e) {
      debugPrint('撮影エラー: $e');
    }
  }
}
