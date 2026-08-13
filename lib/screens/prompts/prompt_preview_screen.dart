import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/services/dialog_service.dart';

class PromptPreviewScreen extends StatefulWidget {
  final String prompt;
  final String? content;

  const PromptPreviewScreen({
    super.key,
    required this.prompt,
    this.content,
  });

  @override
  State<PromptPreviewScreen> createState() => _PromptPreviewScreenState();
}

class _PromptPreviewScreenState extends State<PromptPreviewScreen> {
  bool _isTesting = false;
  String? _testResult;
  String? _errorMessage;

  Future<void> _testPrompt() async {
    setState(() {
      _isTesting = true;
      _errorMessage = null;
      _testResult = null;
    });

    try {
      final groqProvider = context.read<GroqProvider>();
      
      if (!groqProvider.isInitialized) {
        setState(() {
          _errorMessage = 'Groq service not initialized. Please configure your API key in settings.';
          _isTesting = false;
        });
        return;
      }

      // Use the Groq service to test the prompt with a simple content summary
      final testContent = widget.content ?? 'Test content for prompt validation';
      final response = await groqProvider.service.summarizeContent(
        content: '$testContent\n\nPrompt: ${widget.prompt}',
        maxLength: 500,
      );
      
      if (!mounted) return;
      
      setState(() {
        _testResult = response;
        _isTesting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error testing prompt: $e';
        _isTesting = false;
      });
    }
  }

  void _copyPrompt() {
    Clipboard.setData(ClipboardData(text: widget.prompt));
    DialogService.showSuccess(context, 'Prompt copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prompt Preview',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyPrompt,
            tooltip: 'Copy Prompt',
          ),
        ],
      ),
      backgroundColor: isDark ? AppTheme.slate900 : AppTheme.slate50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prompt Section
            Text(
              'Generated Prompt',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
              ),
              child: Text(
                widget.prompt,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testPrompt,
                icon: _isTesting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isTesting ? 'Testing...' : 'Test with AI',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bambooGreen600,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.red50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.red200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.red600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.red700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Test Result
            if (_testResult != null) ...[
              Text(
                'AI Response',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Variables Info
            if (widget.content != null) ...[
              Text(
                'Input Content',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                  ),
                ),
                child: Text(
                  widget.content!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                    height: 1.6,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}