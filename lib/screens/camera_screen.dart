import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CameraScreen extends StatefulWidget {
  final String employeeName;

  const CameraScreen({super.key, required this.employeeName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  XFile? _photo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  Future<void> _takePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (photo == null && mounted) {
      Navigator.pop(context);
      return;
    }
    if (mounted) setState(() => _photo = photo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto Selfie')),
      body: _photo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photo!.path),
                      height: 360,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShadCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text('Karyawan',
                            style: TextStyle(color: Colors.grey)),
                        const Spacer(),
                        Text(widget.employeeName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: () => Navigator.pop(context, _photo),
                      leading: const Icon(Icons.qr_code_scanner, size: 16),
                      child: const Text('Lanjut Scan Barcode'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton.outline(
                      onPressed: _takePhoto,
                      leading: const Icon(Icons.camera_alt, size: 16),
                      child: const Text('Ambil Ulang'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
