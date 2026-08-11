# QuizSnap Branding Package

A complete branding package for QuizSnap, an offline-first AI-powered study and flashcard application.

---

## Package Contents

### 📁 Directory Structure

```
assets/branding/
├── README.md                           # This file
├── INTEGRATION_GUIDE.md               # Complete integration instructions
├── AI_IMAGE_PROMPTS.md                # AI image generation prompts
├── flutter_launcher_icons_config.yaml # Launcher icons configuration
├── flutter_native_splash_config.yaml  # Splash screen configuration
├── logo_light.png                     # [To be generated] Horizontal logo (light)
├── logo_dark.png                      # [To be generated] Horizontal logo (dark)
├── icon_light.png                     # [To be generated] Launcher icon (light bg)
├── icon_dark.png                      # [To be generated] Launcher icon (dark bg)
├── icon_foreground.png                # [To be generated] Adaptive icon foreground
├── splash_light.png                   # [To be generated] Splash screen (light)
├── splash_dark.png                    # [To be generated] Splash screen (dark)
└── loading_logo.png                   # [To be generated] Loading animation logo
```

### 🎨 Flutter Widgets

```
lib/shared/widgets/
├── app_loading_screen.dart            # Animated loading screen widget
└── welcome_screen.dart               # Welcome/onboarding screen widget
```

### ⚙️ Configuration Files

```
pubspec.yaml                          # Updated with branding assets and configs
```

---

## Brand Identity

### App Name
**QuizSnap**

### Tagline
"Study smarter with AI-powered flashcards."

### Primary Colors
- **Bamboo Green:** `#16A34A` (RGB: 22, 163, 74)
- **Slate Gray:** `#334155` (RGB: 51, 65, 85)  
- **White:** `#FFFFFF` (RGB: 255, 255, 255)

### Secondary Accent
- **Blue:** `#3B82F6` (RGB: 59, 130, 246)

### Typography
- **Font:** Poppins
- **Style:** Bold, rounded, highly readable

---

## Quick Start

### 1. Generate Visual Assets

Use the prompts in `AI_IMAGE_PROMPTS.md` with your preferred AI image generator to create the required PNG files.

### 2. Add Assets to Project

Place the generated images in `assets/branding/`

### 3. Generate Icons and Splash Screens

```bash
# Generate launcher icons
flutter pub run flutter_launcher_icons

# Generate splash screens  
dart run flutter_native_splash:create
```

### 4. Integrate Widgets

Use the provided widgets in your Flutter code:

```dart
// Loading screen
import '../shared/widgets/app_loading_screen.dart';
AppLoadingScreen(message: 'Loading your library…');

// Welcome screen
import '../shared/widgets/welcome_screen.dart';
WelcomeScreen(onGetStarted: () => Navigator.pushReplacementNamed(context, '/home'));
```

### 5. Test

```bash
flutter clean
flutter pub get
flutter run
```

---

## Detailed Instructions

For complete step-by-step integration instructions, see **[INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)**.

For AI image generation prompts, see **[AI_IMAGE_PROMPTS.md](./AI_IMAGE_PROMPTS.md)**.

---

## Features

### ✅ Launcher Icons
- Adaptive Android icons with foreground/background layers
- iOS support (configurable)
- Light and dark theme variants
- Monochrome adaptive foreground

### ✅ Splash Screens
- Theme-aware (light/dark)
- Android 12+ Material You support
- Smooth fade-in transitions
- Customizable branding

### ✅ Loading Screen
- Animated logo with pulse effect
- Rotating loading messages
- Progress indicator
- Theme-aware colors
- Multiple variants (full, simple, overlay)

### ✅ Welcome Screen
- First-launch branding
- Customizable content
- Call-to-action button
- Terms and privacy links
- Theme-aware design

### ✅ Design System Integration
- Consistent with AppTheme
- Uses bambooGreen600 primary color
- Poppins typography
- Material Design 3

---

## Design Philosophy

The QuizSnap branding embodies:

- **Modern:** Clean, flat design with minimal details
- **Educational:** Flashcards, books, learning symbols
- **Intelligent:** Lightning bolts, sparks, neural elements
- **Trustworthy:** Professional, not childish
- **Lightweight:** Not cluttered, easy to recognize
- **Focused:** Emphasizes studying and memory retention

Style references include Quizlet, Duolingo, Notion, and Google Classroom.

---

## Technical Specifications

### Icon Requirements
- **Size:** 1024×1024 PNG
- **Format:** PNG with transparency where needed
- **Safe Zone:** Central 66% for adaptive icons
- **Recognition:** Must be readable at 48×48 pixels

### Splash Screen Requirements
- **Size:** 1080×1920 PNG
- **Format:** PNG
- **Animation:** Smooth 200ms transitions
- **Themes:** Separate light/dark variants

### Color Accuracy
- Use exact hex codes provided
- Test on both light and dark backgrounds
- Ensure accessibility (contrast ratios)
- Maintain consistency across all assets

---

## File Status

### ✅ Completed
- [x] AI image generation prompts
- [x] Asset directory structure
- [x] Flutter launcher icons configuration
- [x] Flutter native splash configuration
- [x] AppLoadingScreen widget
- [x] WelcomeScreen widget
- [x] pubspec.yaml updates
- [x] Integration guide
- [x] Documentation

### 🔄 To Be Generated (User Action Required)
- [ ] logo_light.png
- [ ] logo_dark.png
- [ ] icon_light.png
- [ ] icon_dark.png
- [ ] icon_foreground.png
- [ ] splash_light.png
- [ ] splash_dark.png
- [ ] loading_logo.png

---

## Integration Status

### Configuration Files
- ✅ `pubspec.yaml` - Updated with branding assets and configurations
- ✅ `flutter_launcher_icons_config.yaml` - Ready to use
- ✅ `flutter_native_splash_config.yaml` - Ready to use

### Flutter Widgets
- ✅ `lib/shared/widgets/app_loading_screen.dart` - Created and ready
- ✅ `lib/shared/widgets/welcome_screen.dart` - Created and ready

### Documentation
- ✅ `AI_IMAGE_PROMPTS.md` - Complete prompts for all assets
- ✅ `INTEGRATION_GUIDE.md` - Step-by-step integration instructions
- ✅ `README.md` - This overview document

---

## Next Steps

1. **Generate Assets:** Use `AI_IMAGE_PROMPTS.md` to create visual assets
2. **Place Assets:** Add generated PNG files to `assets/branding/`
3. **Generate Icons:** Run `flutter pub run flutter_launcher_icons`
4. **Generate Splash:** Run `dart run flutter_native_splash:create`
5. **Update Widgets:** Replace placeholder logos in widgets with actual assets
6. **Test:** Verify on both light and dark themes
7. **Deploy:** Build and release with new branding

---

## Support

For detailed integration help, troubleshooting, and customization options, refer to the **[INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)**.

---

## License

This branding package is part of the QuizSnap project. All generated assets should comply with the project's licensing terms.

---

**Version:** 1.0.0  
**Last Updated:** 2026-08-11  
**Status:** Ready for Asset Generation