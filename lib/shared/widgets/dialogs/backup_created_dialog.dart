import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Modern Material 3 bottom-sheet dialog shown after a successful backup.
///
/// Hierarchy:
/// * Header — success icon in a subtle green circular container, title,
///   subtitle.
/// * Information card — File, Saved to, Size.
/// * Actions (full-width, vertical) — Share backup (filled), Open folder
///   (outlined), Done (text).
class BackupCreatedDialog extends StatelessWidget {
  final String fileName;
  final String savedTo;
  final String fileSizeDisplay;

  final VoidCallback onShare;
  final VoidCallback onOpenFolder;
  final VoidCallback onDone;

  const BackupCreatedDialog({
    super.key,
    required this.fileName,
    required this.savedTo,
    required this.fileSizeDisplay,
    required this.onShare,
    required this.onOpenFolder,
    required this.onDone,
  });

  /// Shows the dialog as a modal bottom sheet.
  /// Returns when the user taps any action.
  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required String savedTo,
    required String fileSizeDisplay,
    required VoidCallback onShare,
    required VoidCallback onOpenFolder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BackupCreatedDialog(
        fileName: fileName,
        savedTo: savedTo,
        fileSizeDisplay: fileSizeDisplay,
        onShare: onShare,
        onOpenFolder: onOpenFolder,
        onDone: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, colorScheme),
          const SizedBox(height: 20),
          _buildInfoCard(context, theme, colorScheme),
          const SizedBox(height: 24),
          _buildActions(context, colorScheme),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.emerald500.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppTheme.emerald600,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Backup created',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Your backup was saved successfully.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Information card ────────────────────────────────────────────────

  Widget _buildInfoCard(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.description_outlined,
            label: 'File',
            value: fileName,
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.folder_outlined,
            label: 'Saved to',
            value: savedTo,
            iconColor: colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.data_usage_outlined,
            label: 'Size',
            value: fileSizeDisplay,
            iconColor: AppTheme.emerald600,
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share, size: 20),
          label: const Text('Share backup'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenFolder,
          icon: const Icon(Icons.folder_open, size: 20),
          label: const Text('Open folder'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onDone,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
