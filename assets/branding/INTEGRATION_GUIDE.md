# QuizSnap Branding Integration Guide

This guide provides step-by-step instructions for integrating the complete branding package into QuizSnap.

---

## Overview

The branding package includes:
- **AI Image Generation Prompts** - For creating visual assets
- **Flutter Launcher Icons Configuration** - For app icons
- **Flutter Native Splash Configuration** - For splash screens
- **AppLoadingScreen Widget** - Animated loading screen
- **WelcomeScreen Widget** - First-launch branding screen
- **Updated pubspec.yaml** - Asset references and configurations

---

## Prerequisites

1. Flutter SDK installed and configured
2. QuizSnap project cloned and set up
3. Access to an AI image generator (DALL-E, Midjourney, Stable Diffusion, etc.)

---

## Step 1: Generate Visual Assets

### 1.1 Use AI Image Generation Prompts

Open `assets/branding/AI_IMAGE_PROMPTS.md` and use the provided prompts with your preferred AI image generator.

### 1.2 Required Assets

Generate and save the following files to `assets/branding/`:

```
assets/branding/
├── logo_light.png              # Horizontal logo for light theme
├── logo_dark.png               # Horizontal logo for dark theme  
├── icon_light.png              # Main launcher icon (light bg)
├── icon_dark.png              # Main launcher icon (dark bg)
├── icon_foreground.png        # Adaptive icon foreground (transparent)
├── splash_light.png           # Splash screen (light theme)
├── splash_dark.png            # Splash screen (dark theme)
└── loading_logo.png           # Simplified logo for animations
```

### 1.3 Asset Specifications

- **Icons:** 1024×1024 PNG
- **Splash Screens:** 1080×1920 PNG
- **Loading Logo:** 512×512 PNG
- **Logos:** Transparent PNG, appropriate dimensions
- **Colors:** Use bambooGreen600 (#16A34A), slate700 (#334155), white (#FFFFFF)

---

## Step 2: Verify Asset Placement

### 2.1 Check Directory Structure

Ensure your assets are correctly placed:

```powershell
Get-ChildItem assets/branding
```

Expected output:
```
    Directory: C:\wamp64\www\QuizSnap\assets\branding

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        date            time            size AI_IMAGE_PROMPTS.md
-a----        date            time            size flutter_launcher_icons_config.yaml
-a----        date            time            size flutter_native_splash_config.yaml
-a----        date            time            size INTEGRATION_GUIDE.md
-a----        date            time            size icon_light.png
-a----        date            time            size icon_dark.png
-a----        date            time            size icon_foreground.png
-a----        date            time            size logo_light.png
-a----        date            time            size logo_dark.png
-a----        date            time            size splash_light.png
-a----        date            time            size splash_dark.png
-a----        date            time            size loading_logo.png
```

---

## Step 3: Update Flutter Widgets

### 3.1 AppLoadingScreen Widget

The widget is already created at `lib/shared/widgets/app_loading_screen.dart`.

**To use the loading screen:**

```dart
import '../shared/widgets/app_loading_screen.dart';

// Basic usage
AppLoadingScreen();

// With custom message
AppLoadingScreen(
  message: 'Loading your flashcards...',
);

// Without progress indicator
AppLoadingScreen(
  message: 'Syncing data...',
  showProgress: false,
);
```

**Replace placeholder logo:**

In `lib/shared/widgets/app_loading_screen.dart`, update the `_buildLogo` method:

```dart
Widget _buildLogo(BuildContext context) {
  return Image.asset(
    'assets/branding/loading_logo.png',
    width: 120,
    height: 120,
  );
}
```

### 3.2 WelcomeScreen Widget

The widget is already created at `lib/shared/widgets/welcome_screen.dart`.

**To use the welcome screen:**

```dart
import '../shared/widgets/welcome_screen.dart';

// Basic usage
WelcomeScreen(
  onGetStarted: () {
    // Navigate to home screen
    Navigator.pushReplacementNamed(context, '/home');
  },
);

// With custom content
WelcomeScreen(
  onGetStarted: () {
    // Handle get started action
  },
  customTitle: 'Ready to Study?',
  customDescription: 'Your AI-powered flashcards are waiting.',
  buttonText: 'Start Learning',
);
```

**Replace placeholder logo:**

In `lib/shared/widgets/welcome_screen.dart`, update the `_buildLogo` method:

```dart
Widget _buildLogo(BuildContext context) {
  return Image.asset(
    Theme.of(context).brightness == Brightness.dark
        ? 'assets/branding/logo_dark.png'
        : 'assets/branding/logo_light.png',
    width: 200,
    height: 200,
  );
}
```

---

## Step 4: Generate Launcher Icons

### 4.1 Verify Configuration

The `pubspec.yaml` has been updated with the new configuration:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/branding/icon_light.png"
  adaptive_icon_foreground: "assets/branding/icon_foreground.png"
  adaptive_icon_background: "#16A34A"
  remove_alpha_ios: true
  min_sdk_android: 21
```

### 4.2 Generate Icons

Run the following command:

```bash
flutter pub run flutter_launcher_icons
```

This will generate all required icon sizes for Android and iOS.

### 4.3 Verify Generated Icons

Check the generated icons:

```powershell
# Android
Get-ChildItem android/app/src/main/res

# iOS (if enabled)
Get-ChildItem ios/Runner/Assets.xcassets/AppIcon.appiconset
```

---

## Step 5: Generate Splash Screens

### 5.1 Verify Configuration

The `pubspec.yaml` has been updated with the new configuration:

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/branding/splash_light.png
  color_dark: "#020617"
  image_dark: assets/branding/splash_dark.png
  android_12:
    image: assets/branding/icon_foreground.png
    color: "#16A34A"
    icon_background_color: "#16A34A"
  android: true
  ios: false
  web: false
```

### 5.2 Generate Splash Screens

Run the following command:

```bash
dart run flutter_native_splash:create
```

This will generate splash screen resources for Android.

### 5.3 Verify Generated Splash

Check the generated splash files:

```powershell
# Android
Get-ChildItem android/app/src/main/res/drawable*
```

---

## Step 6: Update Dependencies

### 6.1 Install Dependencies

Ensure all dependencies are installed:

```bash
flutter pub get
```

### 6.2 Verify Required Packages

Check that these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0  # For Poppins font
  
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.9
```

---

## Step 7: Test the Integration

### 7.1 Clean Build

Perform a clean build to ensure all assets are properly included:

```bash
flutter clean
flutter pub get
```

### 7.2 Test on Different Platforms

#### Android

```bash
flutter run -d android
```

Test:
- Launcher icon appears correctly
- Splash screen displays on app launch
- Loading screen animations work smoothly
- Welcome screen displays properly on first launch

#### Light/Dark Theme Testing

Toggle between light and dark themes to verify:
- Splash screen changes correctly
- Loading screen colors adapt
- Welcome screen colors adapt
- All assets use correct theme variants

### 7.3 Asset Loading Verification

Add debug code to verify assets load correctly:

```dart
// In your main.dart or startup code
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test asset loading
  try {
    await precacheImage(AssetImage('assets/branding/icon_light.png'), context);
    await precacheImage(AssetImage('assets/branding/splash_light.png'), context);
    await precacheImage(AssetImage('assets/branding/loading_logo.png'), context);
    print('✓ Branding assets loaded successfully');
  } catch (e) {
    print('✗ Error loading branding assets: $e');
  }
  
  runApp(MyApp());
}
```

---

## Step 8: Integration with Existing Screens

### 8.1 Update Main Loading Screen

Replace any existing loading screens with `AppLoadingScreen`:

```dart
// In your existing loading logic
import '../shared/widgets/app_loading_screen.dart';

// Replace old loading widget with:
AppLoadingScreen(
  message: 'Preparing your study library…',
);
```

### 8.2 Update Onboarding Flow

Integrate `WelcomeScreen` into your onboarding:

```dart
// In lib/screens/onboarding/onboarding_screen.dart
import '../../shared/widgets/welcome_screen.dart';

// Add as first page or replace existing onboarding
WelcomeScreen(
  onGetStarted: () {
    // Continue to existing onboarding or main app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OnboardingScreen()),
    );
  },
),
```

### 8.3 Add Branding to Settings/Profile

Use the `WelcomeWidget` in settings or profile screens:

```dart
import '../../shared/widgets/welcome_screen.dart';

// In your settings screen
WelcomeWidget(
  title: 'QuizSnap Pro',
  subtitle: 'Unlock advanced features',
  onAction: () {
    // Navigate to upgrade screen
  },
  actionText: 'Upgrade',
),
```

---

## Step 9: Troubleshooting

### 9.1 Assets Not Loading

**Problem:** Images don't appear in the app.

**Solution:**
1. Verify assets are in `assets/branding/`
2. Check `pubspec.yaml` includes `assets/branding/`
3. Run `flutter clean && flutter pub get`
4. Restart the app

### 9.2 Launcher Icons Not Updating

**Problem:** Old launcher icon still appears.

**Solution:**
1. Uninstall the app from the device
2. Run `flutter pub run flutter_launcher_icons`
3. Rebuild and reinstall the app
4. Clear device home screen cache

### 9.3 Splash Screen Not Showing

**Problem:** Splash screen doesn't appear on launch.

**Solution:**
1. Run `dart run flutter_native_splash:create`
2. Check `android/app/src/main/res/drawable*` for generated files
3. Verify `android/app/src/main/res/values/styles.xml` was updated
4. Clean and rebuild: `flutter clean && flutter run`

### 9.4 Theme Issues

**Problem:** Dark theme assets not loading correctly.

**Solution:**
1. Verify both `splash_light.png` and `splash_dark.png` exist
2. Check theme detection logic in widgets
3. Test theme switching in the app
4. Ensure `color_dark` and `image_dark` are set in configuration

---

## Step 10: Final Verification Checklist

- [ ] All AI-generated assets placed in `assets/branding/`
- [ ] `pubspec.yaml` includes `assets/branding/`
- [ ] Launcher icons generated successfully
- [ ] Splash screens generated successfully
- [ ] AppLoadingScreen widget integrated
- [ ] WelcomeScreen widget integrated
- [ ] Light theme works correctly
- [ ] Dark theme works correctly
- [ ] No asset loading errors
- [ ] App launches without issues
- [ ] Icons appear on home screen
- [ ] Splash screen displays on launch

---

## Additional Customization

### Custom Loading Messages

Edit the loading messages in `lib/shared/widgets/app_loading_screen.dart`:

```dart
static const List<String> _loadingMessages = [
  'Preparing your study library…',
  'Loading flashcards…',
  'Checking AI settings…',
  'Almost ready…',
  // Add your custom messages here
];
```

### Custom Welcome Content

Customize the welcome screen by passing parameters:

```dart
WelcomeScreen(
  onGetStarted: () => Navigator.pushReplacementNamed(context, '/home'),
  customTitle: 'Your Custom Title',
  customDescription: 'Your custom description here.',
  buttonText: 'Your Button Text',
),
```

### Brand Colors

To modify brand colors, update `lib/core/theme/app_theme.dart`:

```dart
static const Color bambooGreen600 = Color(0xFF16A34A); // Primary green
static const Color slate700 = Color(0xFF334155);        // Secondary slate
```

Then regenerate assets with new colors and update configurations.

---

## Maintenance

### Updating Assets

When updating visual assets:
1. Replace files in `assets/branding/`
2. Run `flutter pub run flutter_launcher_icons`
3. Run `dart run flutter_native_splash:create`
4. Test on both light and dark themes

### Version Control

Ensure generated files are properly handled in `.gitignore`:

```
# Generated files
android/app/src/main/res/mipmap-*/
android/app/src/main/res/drawable-*/launch_*
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

But keep the source assets in `assets/branding/` under version control.

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter documentation for [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)
3. Review Flutter documentation for [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)
4. Verify AI-generated assets meet specifications

---

## Summary

This integration guide provides a complete branding package for QuizSnap that includes:

✅ **AI Image Generation Prompts** - Ready-to-use prompts for all visual assets  
✅ **Asset Structure** - Organized directory for branding files  
✅ **Launcher Icons** - Adaptive icons for Android and iOS  
✅ **Splash Screens** - Theme-aware splash screens  
✅ **Loading Screen** - Animated loading widget  
✅ **Welcome Screen** - First-launch branding screen  
✅ **Configuration Files** - Ready-to-use Flutter configurations  
✅ **Integration Guide** - Step-by-step instructions  

The branding is consistent with the QuizSnap AppTheme design system using bambooGreen600 (#16A34A), slate700 (#334155), and white (#FFFFFF) as the primary colors, creating a modern, educational, and intelligent visual identity.