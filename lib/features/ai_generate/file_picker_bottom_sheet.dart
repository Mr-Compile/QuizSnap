import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/document_extraction_service.dart';
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
            'Select ${widget.fileType.toUpperCase()} File',
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
        default:
          result = await FilePicker.platform.pickFiles();
      }

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        if (!mounted) return;
        
        Navigator.of(context).pop();
        
        // Navigate to document scope selection screen
        if (widget.fileType.toLowerCase() == 'pdf') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DocumentScopeSelectionScreen(
                file: file,
                fileType: widget.fileType,
              ),
            ),
          );
        } else if (widget.fileType.toLowerCase() == 'txt') {
          // For TXT, extract text and go to text preview
          try {
            final text = await DocumentExtractionService.extractFromFile(file);
            if (!mounted) return;
            
            final fileName = file.path.split('/').last;
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TextPreviewScreen(
                  text: text,
                  source: fileName,
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to extract text: $e')),
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

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }
}