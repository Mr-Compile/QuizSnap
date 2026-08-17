import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/file_management_service.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/unified_text_cleaner.dart';
import 'document_scope_selection_screen.dart';
import 'text_preview_screen.dart';

class FilePickerBottomSheet extends StatefulWidget {
  final String fileType;

  const FilePickerBottomSheet({
    super.key,
    required this.fileType,
  });

  @override
  State<FilePickerBottomSheet> createState() => _FilePickerBottomSheetState();
}

class _FilePickerBottomSheetState extends State<FilePickerBottomSheet> {
  bool _isLoading = false;
  String? _errorMessage;
  final FileManagementService _fileManagementService = FileManagementService();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            _pickerTitle(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a file from your device',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pickFile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Browse Files'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request storage permission
      final status = await _requestStoragePermission();
      if (!status) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Storage permission is required to access files';
        });
        return;
      }

      FilePickerResult? result;
      
      switch (widget.fileType.toLowerCase()) {
        case 'pdf':
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          break;
        case 'txt':
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['txt'],
          );
          break;
        case 'docx':
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['docx'],
          );
          break;
        case 'powerpoint':
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['ppt', 'pptx'],
          );
          break;
        case 'image':
          result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: true,
          );
          break;
        default:
          result = await FilePicker.platform.pickFiles();
      }

      if (result != null && result.files.isNotEmpty) {
        final selectedFiles = result.files.where((f) => f.path != null).toList();

        if (selectedFiles.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (widget.fileType.toLowerCase() == 'image') {
          await _processSelectedImages(selectedFiles);
        } else {
          final originalFile = File(selectedFiles.first.path!);

          // Copy file to app storage to avoid permission issues
          final copiedFilePath = await _fileManagementService.copyFileToAppStorage(originalFile);
          final copiedFile = File(copiedFilePath);

          if (!mounted) return;

          // Close the bottom sheet first.
          Navigator.of(context).pop();

          // Navigate directly to the review/extracted-content screen and
          // communicate the successful import through the destination screen.
          // Do NOT show a success dialog here; that keeps stale state alive.

          if (widget.fileType.toLowerCase() == 'pdf') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DocumentScopeSelectionScreen(
                  file: copiedFile,
                  fileType: widget.fileType,
                  showImportSuccess: true,
                ),
              ),
            );
          } else if (widget.fileType.toLowerCase() == 'txt') {
            // For TXT, extract text and go to text preview
            try {
              final text = await DocumentExtractionService.extractFromFile(copiedFile);
              if (!mounted) return;

              final fileName = copiedFile.path.split('/').last;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TextPreviewScreen(
                    text: text,
                    source: fileName,
                    showImportSuccess: true,
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              DialogService.showError(context, 'Failed to extract text: $e');
            }
          } else if (widget.fileType.toLowerCase() == 'docx') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DocumentScopeSelectionScreen(
                  file: copiedFile,
                  fileType: widget.fileType,
                  showImportSuccess: true,
                ),
              ),
            );
          } else if (widget.fileType.toLowerCase() == 'powerpoint' ||
              widget.fileType.toLowerCase() == 'pptx' ||
              widget.fileType.toLowerCase() == 'ppt') {
            final actualType = _actualFileType(copiedFile);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DocumentScopeSelectionScreen(
                  file: copiedFile,
                  fileType: actualType,
                  showImportSuccess: true,
                ),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  String _pickerTitle() {
    final type = widget.fileType.toLowerCase();
    if (type == 'powerpoint') return 'Select PowerPoint File';
    return 'Select ${widget.fileType.toUpperCase()} File';
  }

  String _actualFileType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'ppt' || extension == 'pptx') return extension;
    return widget.fileType;
  }

  Future<void> _processSelectedImages(List<PlatformFile> selectedFiles) async {
    try {
      // Copy each selected image to app storage to avoid permission issues
      final copiedImagePaths = <String>[];
      for (final file in selectedFiles) {
        final originalFile = File(file.path!);
        final copiedPath = await _fileManagementService.copyFileToAppStorage(originalFile);
        copiedImagePaths.add(copiedPath);
      }

      if (!mounted) return;

      // OCR all selected images and combine the recognized text
      final textRecognizer = TextRecognizer();
      String combinedText;
      try {
        final buffer = StringBuffer();
        for (final imagePath in copiedImagePaths) {
          final inputImage = InputImage.fromFilePath(imagePath);
          final recognizedText = await textRecognizer.processImage(inputImage);
          if (buffer.isNotEmpty) {
            buffer.write('\n\n');
          }
          buffer.write(recognizedText.text);
        }
        combinedText = OcrTextCleaner.clean(buffer.toString());
      } finally {
        await textRecognizer.close();
      }

      if (!mounted) return;

      final source = copiedImagePaths.length == 1
          ? selectedFiles.first.name
          : 'Image OCR (${copiedImagePaths.length} images)';

      // Close the bottom sheet first
      Navigator.of(context).pop();

      // Navigate to text preview with the combined OCR text
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            text: combinedText,
            source: source,
            showImportSuccess: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        DialogService.showError(context, 'Failed to process images: $e');
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try multiple permission types for better compatibility
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }
      
      // Try manage external storage for Android 11+
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }
      
      // Try photos permission for media files
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        return true;
      }
      
      if (storageStatus.isPermanentlyDenied || manageStatus.isPermanentlyDenied) {
        // Show dialog to guide user to settings
        _showPermissionDialog();
        return false;
      }
      return false;
    }
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to import files. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}