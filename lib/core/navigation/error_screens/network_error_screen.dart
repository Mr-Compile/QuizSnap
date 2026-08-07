import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';

/// Screen displayed when network operations fail
class NetworkErrorScreen extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const NetworkErrorScreen({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Error'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Connection Error',
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                message ?? 'Please check your internet connection and try again.',
                style: AppTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              CustomButton(
                text: 'Try Again',
                onPressed: onRetry ?? () => Navigator.of(context).pop(),
                icon: Icons.refresh,
                fullWidth: false,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}