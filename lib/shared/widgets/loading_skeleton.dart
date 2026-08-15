import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Base skeleton block — a theme-aware placeholder rectangle.
///
/// Uses [colorScheme.onSurface] with low alpha so it adapts correctly
/// to both light and dark themes.
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

/// Generic card skeleton — a card with three text lines of varying width.
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

/// Generic list skeleton — a non-scrollable list of [CardSkeleton]s.
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

// ─────────────────────────────────────────────────────────────────────
//  Screen-specific skeletons
//  Each skeleton approximates the actual content layout of its screen
//  so the loading → content transition feels natural without layout
//  jumping.
// ─────────────────────────────────────────────────────────────────────

/// Skeleton for the Analytics Dashboard screen.
///
/// Approximates:
///   Greeting header → 3 highlight chips → Quick Actions grid →
///   Statistics cards → Chart placeholder
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting header
          LoadingSkeleton(height: 24, width: 200),
          const SizedBox(height: AppTheme.spacing1),
          LoadingSkeleton(height: 16, width: 280),
          const SizedBox(height: AppTheme.spacing4),
          // 3 highlight chips
          Row(
            children: [
              Expanded(child: _buildHighlightChipSkeleton(context)),
              const SizedBox(width: AppTheme.spacing2),
              Expanded(child: _buildHighlightChipSkeleton(context)),
              const SizedBox(width: AppTheme.spacing2),
              Expanded(child: _buildHighlightChipSkeleton(context)),
            ],
          ),
          const SizedBox(height: AppTheme.spacing6),
          // Quick Actions title
          LoadingSkeleton(height: 18, width: 120),
          const SizedBox(height: AppTheme.spacing3),
          // Quick Actions 2x2 grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            mainAxisSpacing: AppTheme.spacing2,
            crossAxisSpacing: AppTheme.spacing2,
            children: List.generate(4, (_) => _buildQuickActionSkeleton(context)),
          ),
          const SizedBox(height: AppTheme.spacing6),
          // Statistics cards
          LoadingSkeleton(height: 18, width: 100),
          const SizedBox(height: AppTheme.spacing3),
          _buildStatsCardSkeleton(context),
          const SizedBox(height: AppTheme.spacing6),
          // Chart placeholder
          LoadingSkeleton(height: 18, width: 80),
          const SizedBox(height: AppTheme.spacing3),
          LoadingSkeleton(
            height: 180,
            width: double.infinity,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChipSkeleton(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing2,
          vertical: AppTheme.spacing2,
        ),
        child: Column(
          children: [
            LoadingSkeleton(height: 24, width: 24, borderRadius: BorderRadius.circular(12)),
            const SizedBox(height: AppTheme.spacing1),
            LoadingSkeleton(height: 16, width: 50),
            const SizedBox(height: 2),
            LoadingSkeleton(height: 12, width: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionSkeleton(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingSkeleton(height: 48, width: 48, borderRadius: BorderRadius.circular(24)),
          const SizedBox(height: AppTheme.spacing2),
          LoadingSkeleton(height: 12, width: 60),
        ],
      ),
    );
  }

  Widget _buildStatsCardSkeleton(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItemSkeleton(),
            _buildStatItemSkeleton(),
            _buildStatItemSkeleton(),
            _buildStatItemSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Column(
      children: [
        LoadingSkeleton(height: 28, width: 28, borderRadius: BorderRadius.circular(14)),
        const SizedBox(height: AppTheme.spacing1),
        LoadingSkeleton(height: 20, width: 40),
        const SizedBox(height: 2),
        LoadingSkeleton(height: 12, width: 50),
      ],
    );
  }
}

/// Skeleton for the Library screen.
///
/// Approximates folder cards: circle avatar + name + deck count.
class LibrarySkeleton extends StatelessWidget {
  final int itemCount;

  const LibrarySkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Column(
        children: [
          // Search bar skeleton
          LoadingSkeleton(
            height: 56,
            width: double.infinity,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Folder card skeletons
          ...List.generate(itemCount, (index) => _buildFolderCardSkeleton(context)),
        ],
      ),
    );
  }

  Widget _buildFolderCardSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Row(
            children: [
              LoadingSkeleton(height: 48, width: 48, borderRadius: BorderRadius.circular(24)),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 18, width: double.infinity),
                    const SizedBox(height: AppTheme.spacingXs),
                    LoadingSkeleton(height: 14, width: 80),
                  ],
                ),
              ),
              LoadingSkeleton(height: 24, width: 24, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Folder Details screen.
///
/// Approximates: folder header card → search bar → deck list.
class FolderDetailsSkeleton extends StatelessWidget {
  final int itemCount;

  const FolderDetailsSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(height: 24, width: 200),
                  const SizedBox(height: AppTheme.spacingSm),
                  LoadingSkeleton(height: 16, width: double.infinity),
                  const SizedBox(height: AppTheme.spacingSm),
                  LoadingSkeleton(height: 14, width: 80),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Search bar
          LoadingSkeleton(
            height: 56,
            width: double.infinity,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Deck card skeletons
          ...List.generate(itemCount, (index) => _buildDeckCardSkeleton(context)),
        ],
      ),
    );
  }

  Widget _buildDeckCardSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Row(
            children: [
              LoadingSkeleton(height: 48, width: 48, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 18, width: double.infinity),
                    const SizedBox(height: AppTheme.spacingXs),
                    LoadingSkeleton(height: 14, width: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Deck Details screen.
///
/// Approximates: deck header (icon + name) → stats card → exam button →
/// study/manage buttons → flashcard list.
class DeckDetailsSkeleton extends StatelessWidget {
  final int itemCount;

  const DeckDetailsSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck header: icon + name
          Row(
            children: [
              LoadingSkeleton(height: 64, width: 64, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              const SizedBox(width: AppTheme.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 20, width: double.infinity),
                    const SizedBox(height: AppTheme.spacingXs),
                    LoadingSkeleton(height: 16, width: 200),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Stats card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(height: 16, width: 80),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatSkeleton(),
                      _buildStatSkeleton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Exam button
          LoadingSkeleton(
            height: 48,
            width: double.infinity,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Flashcards section title
          LoadingSkeleton(height: 16, width: 100),
          const SizedBox(height: AppTheme.spacingSm),
          // Study/Manage buttons
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 48,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: LoadingSkeleton(
                  height: 48,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Flashcard list skeletons
          ...List.generate(itemCount, (index) => _buildFlashcardSkeleton(context)),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        LoadingSkeleton(height: 32, width: 32, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: AppTheme.spacingXs),
        LoadingSkeleton(height: 14, width: 40),
        const SizedBox(height: AppTheme.spacingXs),
        LoadingSkeleton(height: 12, width: 50),
      ],
    );
  }

  Widget _buildFlashcardSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Row(
            children: [
              LoadingSkeleton(height: 24, width: 24, borderRadius: BorderRadius.circular(4)),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: double.infinity),
                    const SizedBox(height: AppTheme.spacingXs),
                    LoadingSkeleton(height: 14, width: 150),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Trash screen list items.
///
/// Approximates: icon + name + deleted date + restore/delete buttons.
class TrashListSkeleton extends StatelessWidget {
  final int itemCount;

  const TrashListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildTrashItemSkeleton(context),
    );
  }

  Widget _buildTrashItemSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Row(
            children: [
              LoadingSkeleton(height: 40, width: 40, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: double.infinity),
                    const SizedBox(height: AppTheme.spacingXs),
                    LoadingSkeleton(height: 12, width: 80),
                  ],
                ),
              ),
              LoadingSkeleton(height: 24, width: 24, borderRadius: BorderRadius.circular(4)),
              const SizedBox(width: AppTheme.spacingSm),
              LoadingSkeleton(height: 24, width: 24, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ),
      ),
    );
  }
}
