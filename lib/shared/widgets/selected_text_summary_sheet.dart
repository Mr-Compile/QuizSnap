import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet/card showing the selected text stats and an action.
class SelectedTextSummarySheet extends StatelessWidget {
  final String selectedText;
  final VoidCallback? onAnalyze;

  const SelectedTextSummarySheet({
    super.key,
    required this.selectedText,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '${selectedText.length} characters selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedText.trim().isEmpty ? null : onAnalyze,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Analyze Selection'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
