import 'package:flutter/material.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';

/// About QuizSnap screen.
///
/// Displays the application identity, a concise description, developer credit,
/// and version/build metadata using the established QuizSnap Material 3
/// components and theme tokens.
class AboutQuizSnapScreen extends StatelessWidget {
  const AboutQuizSnapScreen({super.key});

  /// Application version that already exists in the codebase.
  /// Kept as a single source of truth for the About and Settings screens.
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'About QuizSnap',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacing4,
              AppTheme.spacing4,
              AppTheme.spacing4,
              AppTheme.spacing4 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildBranding(context, colorScheme, isSmall),
              const SizedBox(height: AppTheme.spacing4),
              _buildDescriptionCard(context, colorScheme),
              const SizedBox(height: AppTheme.spacing4),
              _buildDeveloperCard(context, colorScheme),
              const SizedBox(height: AppTheme.spacing4),
              _buildAppInfoCard(context, colorScheme),
              const SizedBox(height: AppTheme.spacing4),
              _buildTechnologyCard(context, colorScheme),
              const SizedBox(height: AppTheme.spacing6),
              _buildBackButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(BuildContext context, ColorScheme colorScheme, bool isSmall) {
    return Column(
      children: [
        Semantics(
          label: 'QuizSnap application logo',
          child: Container(
            width: isSmall ? 96 : 120,
            height: isSmall ? 96 : 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/branding/icon_educational.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.school,
                size: isSmall ? 48 : 60,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'QuizSnap',
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Offline Study & Flashcard Application',
          style: AppTheme.bodyLarge.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, ColorScheme colorScheme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'About',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'QuizSnap is an offline-first study and flashcard application '
              'designed to help users create, review, and practice learning materials.',
              style: AppTheme.bodyLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context, ColorScheme colorScheme) {
    return CustomCard(
      child: Semantics(
        label: 'Developer information: Michael R. Torillo, Software Developer',
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.code,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Developer',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Michael R. Torillo',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          'Software Developer',
                          style: AppTheme.bodyMedium.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Designed and developed QuizSnap as an offline-first study and flashcard application.',
                style: AppTheme.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, ColorScheme colorScheme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Application Information',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _buildInfoRow(
              context,
              label: 'Version',
              value: _appVersion,
              labelColor: colorScheme.onSurface.withValues(alpha: 0.7),
              valueColor: colorScheme.onSurface,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              label: 'Platform',
              value: Theme.of(context).platform.toString().split('.').last,
              labelColor: colorScheme.onSurface.withValues(alpha: 0.7),
              valueColor: colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnologyCard(BuildContext context, ColorScheme colorScheme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_suggest,
                  color: colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Technology',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: [
                _buildTechChip(context, colorScheme, 'Flutter'),
                _buildTechChip(context, colorScheme, 'Dart'),
                _buildTechChip(context, colorScheme, 'SQLite'),
                _buildTechChip(context, colorScheme, 'Riverpod'),
                _buildTechChip(context, colorScheme, 'Material 3'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechChip(BuildContext context, ColorScheme colorScheme, String label) {
    return Chip(
      label: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      backgroundColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: labelColor),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return CustomButton(
      text: 'Back to Settings',
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.settingsHome),
      isOutlined: true,
      fullWidth: true,
    );
  }
}
