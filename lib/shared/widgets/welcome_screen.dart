import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A simple welcome screen for first-time users.
/// Features the QuizSnap branding, tagline, and a call-to-action button.
/// Use this for a focused, single-screen onboarding experience.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final String? customTitle;
  final String? customDescription;
  final String? buttonText;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    this.customTitle,
    this.customDescription,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.slate950 : AppTheme.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer for top balance
              const Spacer(),

              // Logo/Brand Image
              _buildLogo(context),

              const SizedBox(height: AppTheme.spacingXl),

              // Welcome Title
              Text(
                customTitle ?? 'Welcome to QuizSnap',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: isDark ? AppTheme.white : AppTheme.slate900,
                  fontWeight: AppTheme.fontBold,
                  fontSize: AppTheme.text3xl,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Description
              Text(
                customDescription ??
                    'Turn your notes into flashcards and quizzes with AI, then study offline anytime.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                  fontSize: AppTheme.textBase,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bambooGreen600,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.roundedLg),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText ?? 'Get Started',
                    style: const TextStyle(
                      fontSize: AppTheme.textBase,
                      fontWeight: AppTheme.fontSemiBold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Optional: Terms and Privacy links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'By continuing, you agree to our ',
                    style: TextStyle(
                      color: isDark ? AppTheme.slate500 : AppTheme.slate500,
                      fontSize: AppTheme.textXs,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showTermsOfService(context);
                    },
                    child: Text(
                      'Terms',
                      style: TextStyle(
                        color: AppTheme.bambooGreen600,
                        fontSize: AppTheme.textXs,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                  ),
                  Text(
                    ' and ',
                    style: TextStyle(
                      color: isDark ? AppTheme.slate500 : AppTheme.slate500,
                      fontSize: AppTheme.textXs,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showPrivacyPolicy(context);
                    },
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: AppTheme.bambooGreen600,
                        fontSize: AppTheme.textXs,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    // Use the launcher icon as the logo since it's available in assets
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.bambooGreen600.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        'assets/launcher_icon.png',
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(
            Icons.flash_on,
            size: 100,
            color: AppTheme.bambooGreen600,
          );
        },
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'QuizSnap Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using QuizSnap, you agree to these terms of service.\n\n'
            '2. Use License\n'
            'QuizSnap grants you a personal, non-exclusive, non-transferable license to use the application for personal use.\n\n'
            '3. User Accounts\n'
            'You are responsible for maintaining the confidentiality of your account and password.\n\n'
            '4. Privacy\n'
            'Your use of QuizSnap is also governed by our Privacy Policy.\n\n'
            '5. Intellectual Property\n'
            'All content and materials in QuizSnap are owned by QuizSnap.\n\n'
            '6. Limitation of Liability\n'
            'QuizSnap shall not be liable for any indirect, incidental, special, or consequential damages.\n\n'
            '7. Termination\n'
            'We reserve the right to terminate or suspend your account at our sole discretion.\n\n'
            '8. Governing Law\n'
            'These terms shall be governed by the laws of the jurisdiction in which QuizSnap is based.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'QuizSnap Privacy Policy\n\n'
            '1. Information We Collect\n'
            'We collect information you provide directly, such as account details and study materials.\n\n'
            '2. How We Use Your Information\n'
            'We use your information to provide, maintain, and improve our services.\n\n'
            '3. Data Storage\n'
            'Your data is stored locally on your device and in our secure cloud infrastructure.\n\n'
            '4. Data Sharing\n'
            'We do not sell your personal data to third parties.\n\n'
            '5. Security\n'
            'We implement appropriate security measures to protect your information.\n\n'
            '6. Your Rights\n'
            'You have the right to access, update, or delete your personal data.\n\n'
            '7. Changes to This Policy\n'
            'We may update this privacy policy from time to time.\n\n'
            '8. Contact Us\n'
            'If you have questions about this policy, please contact our support team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// A compact welcome widget that can be embedded in other screens.
/// Useful for showing branding in settings, profile sections, etc.
class WelcomeWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionText;

  const WelcomeWidget({
    super.key,
    this.title,
    this.subtitle,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900 : AppTheme.slate50,
        borderRadius: BorderRadius.circular(AppTheme.roundedLg),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.bambooGreen600.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_on,
              size: 40,
              color: AppTheme.bambooGreen600,
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Title
          Text(
            title ?? 'Welcome to QuizSnap',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? AppTheme.white : AppTheme.slate900,
              fontWeight: AppTheme.fontSemiBold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Subtitle
          Text(
            subtitle ??
                'Study smarter with AI-powered flashcards',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.slate400 : AppTheme.slate600,
            ),
            textAlign: TextAlign.center,
          ),

          if (onAction != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText ?? 'Learn More',
                style: TextStyle(
                  color: AppTheme.bambooGreen600,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A branded header widget that can be used in screens to show the app identity.
class BrandedHeader extends StatelessWidget {
  final String? title;
  final Widget? action;
  final bool showLogo;

  const BrandedHeader({
    super.key,
    this.title,
    this.action,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900 : AppTheme.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.slate800 : AppTheme.slate200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showLogo) ...[
            // Small logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.bambooGreen600.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flash_on,
                size: 20,
                color: AppTheme.bambooGreen600,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
          ],
          // Title
          Expanded(
            child: Text(
              title ?? 'QuizSnap',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? AppTheme.white : AppTheme.slate900,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
          // Action
          ...action != null ? [action!] : [],
        ],
      ),
    );
  }
}