import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

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
      // TODO: Integrate with Groq service
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      setState(() {
        _testResult = '''Sample AI Response:

This is a simulated response from the AI. In the actual implementation, this will be replaced with the real response from the Groq API.

Question 1: What is the primary function of mitochondria?
A) Protein synthesis
B) Energy production (ATP)
C) DNA storage
D) Cell division
Correct Answer: B
Explanation: Mitochondria are known as the "powerhouse of the cell" because they generate most of the cell's supply of adenosine triphosphate (ATP).

Question 2: Which organelle is responsible for protein synthesis?
A) Lysosome
B) Ribosome
C) Golgi apparatus
D) Vacuole
Correct Answer: B
Explanation: Ribosomes are the cellular structures responsible for protein synthesis. They can be found free in the cytoplasm or attached to the endoplasmic reticulum.''';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error testing prompt: $e';
        _isTesting = false;
      });
    }
  }

  void _copyPrompt() {
    // TODO: Implement clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copied to clipboard')),
    );
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
        backgroundColor: isDark ? AppTheme.slate800 : Colors.white,
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
                color: isDark ? Colors.white : AppTheme.slate800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.slate800 : Colors.white,
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  foregroundColor: Colors.white,
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
                  color: isDark ? Colors.white : AppTheme.slate800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate800 : Colors.white,
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
                  color: isDark ? Colors.white : AppTheme.slate800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate800 : Colors.white,
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