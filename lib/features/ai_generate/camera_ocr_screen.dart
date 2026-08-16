import 'dart:io';
import 'package:flutter/material.dart';
import '../../shared/widgets/app_bar.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/unified_text_cleaner.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/stepper_header.dart';
import 'text_preview_screen.dart';

class CameraOcrScreen extends StatefulWidget {
  const CameraOcrScreen({super.key});

  @override
  State<CameraOcrScreen> createState() => _CameraOcrScreenState();
}

class _CameraOcrScreenState extends State<CameraOcrScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isOcrProcessing = false;
  bool _isTextRecognizerClosed = false;
  String? _errorMessage;
  final List<String> _capturedImagePaths = [];
  TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    if (!_isOcrProcessing && !_isTextRecognizerClosed) {
      _textRecognizer.close();
    }
    super.dispose();
  }

  Future<void> _processImages() async {
    if (_capturedImagePaths.isEmpty || _isOcrProcessing) return;

    if (_isTextRecognizerClosed) {
      _textRecognizer = TextRecognizer();
      _isTextRecognizerClosed = false;
    }

    setState(() {
      _isOcrProcessing = true;
    });

    try {
      final buffer = StringBuffer();

      for (final imagePath in _capturedImagePaths) {
        final inputImage = InputImage.fromFilePath(imagePath);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        if (buffer.isNotEmpty) {
          buffer.write('\n\n');
        }

        buffer.write(recognizedText.text);
      }

      final extractedText = OcrTextCleaner.clean(buffer.toString());

      final source = _capturedImagePaths.length == 1
          ? 'Camera OCR'
          : 'Camera OCR (${_capturedImagePaths.length} images)';

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            text: extractedText,
            source: source,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        DialogService.showError(context, 'Failed to process images: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
        });
      }
      await _textRecognizer.close();
      _isTextRecognizerClosed = true;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission is required';
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      // Initialize camera (prefer back camera)
      _cameraController = CameraController(
        _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scan Document',
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Column(
        children: [
          const StepperHeader(
            currentStep: 1,
            steps: kAiWizardSteps,
          ),
          Expanded(
            child: _errorMessage != null
                ? _buildErrorState()
                : !_isCameraInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCameraView(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        Center(
          child: CameraPreview(_cameraController!),
        ),
        // OCR guide overlay
        Positioned.fill(
          child: CustomPaint(
            painter: OcrGuidePainter(),
          ),
        ),
        // Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_capturedImagePaths.isNotEmpty) ...[
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _capturedImagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_capturedImagePaths[index]),
                                width: 56,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Position text within the frame',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'capture',
                        onPressed: _isProcessing ? null : _captureAndRecognize,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                      ),
                      if (_capturedImagePaths.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        CustomButton(
                          text: _isOcrProcessing
                              ? 'Processing...'
                              : (_capturedImagePaths.length == 1
                                  ? 'Process'
                                  : 'Done (${_capturedImagePaths.length})'),
                          onPressed: _isOcrProcessing ? null : _processImages,
                          isLoading: _isOcrProcessing,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    final currentCamera = _cameraController?.description;
    final currentIndex = _cameras!.indexOf(currentCamera!);
    final nextIndex = (currentIndex + 1) % _cameras!.length;

    await _cameraController?.dispose();
    
    setState(() {
      _isCameraInitialized = false;
    });

    _cameraController = CameraController(
      _cameras![nextIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image and allow additional captures
      final image = await _cameraController!.takePicture();

      setState(() {
        _capturedImagePaths.add(image.path);
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        DialogService.showError(context, 'Failed to capture image: $e');
      }
    }
  }
}

class OcrGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );

    canvas.drawRect(rect, paint);

    // Corner markers
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cornerSize = 20.0;
    final cornerRadius = 4.0;

    // Top-left corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left - cornerSize / 2, rect.top - cornerSize / 2, cornerSize, cornerSize),
        Radius.circular(cornerRadius),
      ),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - cornerSize / 2, rect.top - cornerSize / 2, cornerSize, cornerSize),
        Radius.circular(cornerRadius),
      ),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left - cornerSize / 2, rect.bottom - cornerSize / 2, cornerSize, cornerSize),
        Radius.circular(cornerRadius),
      ),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - cornerSize / 2, rect.bottom - cornerSize / 2, cornerSize, cornerSize),
        Radius.circular(cornerRadius),
      ),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}