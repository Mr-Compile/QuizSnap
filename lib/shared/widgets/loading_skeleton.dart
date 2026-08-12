import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(
              height: 20,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            LoadingSkeleton(
              height: 16,
              width: 150,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            LoadingSkeleton(
              height: 14,
              width: 100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ],
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const CardSkeleton(),
    );
  }
}
