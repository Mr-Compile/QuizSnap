import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A loading screen widget that displays an animated logo with loading messages.
/// Used during app initialization, database loading, and AI setup.
class AppLoadingScreen extends StatefulWidget {
  final String? message;
  final bool showProgress;

  const AppLoadingScreen({
    super.key,
    this.message,
    this.showProgress = true,
  });

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  int _currentMessageIndex = 0;

  static const List<String> _loadingMessages = [
    'Preparing your study library…',
    'Loading flashcards…',
    'Checking AI settings…',
    'Almost ready…',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startMessageRotation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void _startMessageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.slate950 : AppTheme.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: _buildLogo(context),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Loading Message
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.message ?? _loadingMessages[_currentMessageIndex],
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTheme.slate300 : AppTheme.slate600,
                  fontSize: AppTheme.textBase,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Progress Indicator
            if (widget.showProgress)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.bambooGreen600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    // Use the launcher icon as the logo since it's available in assets
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.bambooGreen600,
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bambooGreen600.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/branding/icon_educational.svg',
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return const Icon(
            Icons.flash_on,
            size: 60,
            color: AppTheme.white,
          );
        },
      ),
    );
  }
}

/// A simplified loading screen with just a spinner and message.
/// Use this for shorter loading operations.
class SimpleLoadingScreen extends StatelessWidget {
  final String message;
  final Color? backgroundColor;

  const SimpleLoadingScreen({
    super.key,
    required this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: backgroundColor ?? (isDark ? AppTheme.slate950 : AppTheme.white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bambooGreen600),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.slate300 : AppTheme.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen loading overlay that can be shown on top of existing content.
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.45),
      child: Center(
        child: Card(
          color: colorScheme.surface,
          margin: const EdgeInsets.all(AppTheme.spacingXl),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: AppTheme.textBase,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}