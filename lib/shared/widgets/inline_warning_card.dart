import 'package:flutter/material.dart';

/// Theme-aware inline warning card for validation or quota messages.
class InlineWarningCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const InlineWarningCard({
    super.key,
    required this.message,
    this.icon = Icons.warning,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final container = Theme.of(context).colorScheme.errorContainer;

    return Semantics(
      label: 'Warning: $message',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: container.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
