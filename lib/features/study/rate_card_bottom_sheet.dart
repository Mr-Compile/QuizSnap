import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RateCardBottomSheet extends StatelessWidget {
  final Function(int) onRated;

  const RateCardBottomSheet({
    super.key,
    required this.onRated,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                  Colors.red,
                  0,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildRateButton(
                  context,
                  'Hard',
                  'I remembered with difficulty',
                  Colors.orange,
                  2,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildRateButton(
                  context,
                  'Good',
                  'I remembered correctly',
                  Colors.blue,
                  3,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _buildRateButton(
                  context,
                  'Easy',
                  'I knew it instantly',
                  Colors.green,
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
    Color color,
    int quality,
  ) {
    return ElevatedButton(
      onPressed: () => onRated(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
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
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            description,
            style: AppTheme.bodySmall.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}