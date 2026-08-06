import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SuccessSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.bambooGreen),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}
