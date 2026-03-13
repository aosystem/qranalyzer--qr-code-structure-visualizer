import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageSelectPage extends StatefulWidget {
  const ImageSelectPage({super.key});

  @override
  State<ImageSelectPage> createState() => _ImageSelectPageState();
}

class _ImageSelectPageState extends State<ImageSelectPage> {
  XFile? _selectedImage;
  bool _isProcessing = false;

  int? _imgWidth;
  int? _imgHeight;

  Future<void> _pickImage() async {
    if (kIsWeb) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Read image size
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      _imgWidth = decoded.width;
      _imgHeight = decoded.height;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _returnImage() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      Navigator.pop(context, _selectedImage);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Image"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text("Choose Image"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _selectedImage == null || _isProcessing
                          ? null
                          : _returnImage,
                      icon: const Icon(Icons.check),
                      label: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isProcessing) const LinearProgressIndicator(),
              const SizedBox(height: 16),

              Expanded(
                child: _selectedImage == null
                    ? const Center(child: Text("No image selected"))
                    : Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    if (_imgWidth != null && _imgHeight != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Image size: ${_imgWidth} × ${_imgHeight}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
