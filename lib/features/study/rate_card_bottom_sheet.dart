import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class RateCardBottomSheet extends StatelessWidget {
  final Function(int) onRated;

  const RateCardBottomSheet({
    super.key,
    required this.onRated,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How well did you know this?',
                  style: AppTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                _buildRateButton(
                  context,
                  'Again',
                  'I forgot completely',
                  colorScheme.errorContainer,
                  colorScheme.onErrorContainer,
                  0,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildRateButton(
                  context,
                  'Hard',
                  'I remembered with difficulty',
                  colorScheme.secondaryContainer,
                  colorScheme.onSecondaryContainer,
                  2,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildRateButton(
                  context,
                  'Good',
                  'I remembered correctly',
                  colorScheme.primaryContainer,
                  colorScheme.onPrimaryContainer,
                  3,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildRateButton(
                  context,
                  'Easy',
                  'I knew it instantly',
                  colorScheme.tertiaryContainer,
                  colorScheme.onTertiaryContainer,
                  4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateButton(
    BuildContext context,
    String label,
    String description,
    Color container,
    Color onContainer,
    int quality,
  ) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onRated(quality);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: container,
        foregroundColor: onContainer,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelLarge.copyWith(
              color: onContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            description,
            style: AppTheme.bodySmall.copyWith(
              color: onContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
