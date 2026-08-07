import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';

/// Screen displayed when database is unavailable or corrupted
class DatabaseErrorScreen extends StatelessWidget {
  const DatabaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Error'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storage_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Database Error',
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'We\'re having trouble accessing your data. This might be due to a corrupted database or a temporary issue.',
                style: AppTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              CustomButton(
                text: 'Try Again',
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                ),
                icon: Icons.refresh,
                fullWidth: false,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextButton(
                onPressed: () {
                  // Navigate to database maintenance
                  Navigator.of(context).pushNamed('/settings/database');
                },
                child: const Text('Repair Database'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}