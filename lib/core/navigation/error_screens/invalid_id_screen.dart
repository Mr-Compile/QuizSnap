import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';

/// Screen displayed when a route parameter that should be a numeric id
/// (e.g. `deckId`, `folderId`) cannot be parsed.  This prevents the
/// `FormatException: Invalid radix-10 number` crash that occurred when a
/// non-numeric segment such as `create` was matched by a `:id` route.
class InvalidIdScreen extends StatelessWidget {
  final String paramName;
  final String invalidValue;

  const InvalidIdScreen({
    super.key,
    required this.paramName,
    required this.invalidValue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invalid Link'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Invalid Link',
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'The "$paramName" in this link is not valid'
                '${invalidValue.isEmpty ? '' : ' ("$invalidValue")'}.',
                style: AppTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              CustomButton(
                text: 'Go to Library',
                onPressed: () => GoRouter.of(context).go('/'),
                icon: Icons.library_books,
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
