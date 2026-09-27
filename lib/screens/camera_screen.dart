import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/roster_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/app_bar.dart';
import 'review_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  bool _isInitialising = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitialising = false;
          _error = 'No camera available on this device.';
        });
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialising = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _error = 'Could not start camera: $e';
      });
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Web/desktop fallback: file.path isn't a real file, we use bytes only.
      if (!mounted) return;
      await _handleCapture(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  Future<void> _handleCapture(Uint8List bytes) async {
    // Show loading while Gemini extracts.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    await ref.read(rosterProvider.notifier).extractFromImage(bytes);

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    final state = ref.read(rosterProvider);

    if (!state.isLoading && state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewScreen()),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ShiftSnapAppBar(showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialising) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography,
                  color: AppColors.surface, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppStylesFallback.onDark,
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),

        // "Ensure photo is clear" pill (Component 7)
        Positioned(
          top: 40,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Ensure photo is clear',
              style: AppTextStyles.body,
            ),
          ),
        ),

        // Shutter button
        Positioned(
          bottom: 40,
          child: GestureDetector(
            onTap: _capture,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.surface,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small helper to avoid importing another file just for a text style.
class AppStylesFallback {
  static const onDark = TextStyle(
    color: AppColors.surface,
    fontSize: 16,
  );
}