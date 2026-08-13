import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/models/export.dart';
import 'export_success_screen.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String filePath;
  final ExportResult? exportResult;

  const PdfPreviewScreen({
    super.key,
    required this.filePath,
    this.exportResult,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isSharing = false;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'PDF Preview',
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) async {
                final bytes = await PrintingHelper.getFileBytes(widget.filePath);
                return Uint8List.fromList(bytes);
              },
              allowSharing: false,
              allowPrinting: false,
              pdfFileName: widget.filePath.split('/').last,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Share',
                      icon: Icons.share,
                      isLoading: _isSharing,
                      onPressed: _isSharing ? null : _handleShare,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Print',
                      icon: Icons.print,
                      isLoading: _isPrinting,
                      onPressed: _isPrinting ? null : _handlePrint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Done',
                      isSecondary: true,
                      onPressed: _handleDone,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      await Share.shareXFiles([XFile(widget.filePath)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      final bytes = await PrintingHelper.getFileBytes(widget.filePath);
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: widget.filePath.split('/').last,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _handleDone() {
    if (widget.exportResult != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ExportSuccessScreen(
            exportResult: widget.exportResult!,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}

class PrintingHelper {
  static Future<List<int>> getFileBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }
}