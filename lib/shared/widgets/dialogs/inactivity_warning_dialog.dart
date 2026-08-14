import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Inactivity warning dialog with a live countdown.
///
/// Shown after [SessionTimerConfig.warningThreshold] of inactivity.
/// Displays a countdown from [SessionTimerConfig.warningDuration] to 0.
///
/// Buttons:
/// * **I'm Still Here** — dismisses dialog and resets the inactivity timer.
/// * **Lock Now** — immediately locks the session.
///
/// Use inside a [ListenableBuilder] that rebuilds when the
/// [SessionInactivityService] notifies, so the countdown updates live.
class InactivityWarningDialog extends StatelessWidget {
  final int countdown;
  final VoidCallback onStillHere;
  final VoidCallback onLockNow;

  const InactivityWarningDialog({
    super.key,
    required this.countdown,
    required this.onStillHere,
    required this.onLockNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        elevation: 0,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing6,
          vertical: AppTheme.spacing6,
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing4,
          vertical: AppTheme.spacing8,
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 520 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCountdownIcon(context),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'Session Expiring',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: isTablet ? AppTheme.text2xl : AppTheme.textLg,
                  fontWeight: AppTheme.fontSemiBold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing3),
              Text(
                "You've been inactive for a while. The app will lock in $countdown seconds.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing5),
              _buildActions(context, isTablet, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownIcon(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: countdown / 15,
            strokeWidth: 4,
            color: AppTheme.amber600,
            backgroundColor: AppTheme.amber100,
          ),
          Text(
            '$countdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.amber700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, bool isTablet, ColorScheme colorScheme) {
    final actions = [
      OutlinedButton(
        onPressed: onLockNow,
        child: const Text('Lock Now'),
      ),
      ElevatedButton(
        onPressed: onStillHere,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.bambooGreen600,
          foregroundColor: Colors.white,
        ),
        child: const Text("I'm Still Here"),
      ),
    ];

    if (isTablet) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacing2),
                  child: action,
                ))
            .toList(),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                  child: SizedBox(
                    width: double.infinity,
                    child: action,
                  ),
                ))
            .toList(),
      );
    }
  }
}
