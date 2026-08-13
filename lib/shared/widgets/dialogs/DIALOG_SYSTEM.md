# QuizSnap Modern Dialog System

## Overview

A centralized, Material 3-compliant dialog system that provides a consistent, polished, and accessible user experience across the QuizSnap application. All dialogs are perfectly centered with smooth animations and educational-friendly copy.

## Architecture

### Core Components

- **AppDialog**: Base dialog widget with centered layout, smooth animations, and responsive design
- **SuccessDialog**: Green icon dialog for positive feedback
- **ErrorDialog**: Red icon dialog for errors with retry/close options
- **WarningDialog**: Amber icon dialog for confirmations with cancel/confirm actions
- **InfoDialog**: Blue icon dialog for informational messages
- **ConfirmationDialog**: Neutral dialog for confirmations with destructive action support
- **LoadingDialog**: Non-dismissible loading dialog for long-running operations
- **DialogService**: Centralized service for dialog management with educational-friendly error messages

### File Structure

```
lib/shared/widgets/dialogs/
├── app_dialog.dart              # Base dialog component
├── success_dialog.dart          # Success dialog
├── error_dialog.dart            # Error dialog
├── warning_dialog.dart          # Warning dialog
├── info_dialog.dart            # Info dialog
├── confirmation_dialog.dart    # Confirmation dialog
├── loading_dialog.dart          # Loading dialog
├── dialogs.dart                # Export file for easy imports
└── DIALOG_SYSTEM.md            # This documentation
```

## Design Specifications

### Layout & Spacing

- **Vertical & Horizontal Centering**: All dialogs are perfectly centered on screen
- **Safe Areas**: Respects device safe areas and notches
- **Max Width**:
  - Phone (< 600dp): 90% of screen width
  - Tablet (≥ 600dp): 420-520dp
- **Outer Padding**: 24dp (phone), 32dp (tablet)
- **Section Spacing**: 16dp between elements
- **Icon Circle Size**: 64dp

### Animation

- **Type**: Fade + Scale transition
- **Duration**: 200ms
- **Easing**: Curves.easeOutCubic
- **Implementation**: `showGeneralDialog` with `FadeTransition` and `ScaleTransition`

### Visual Design (Material 3)

#### Container
- **Background**: `colorScheme.surface`
- **Border Radius**: `AppTheme.rounded2xl` (24dp)
- **Elevation**: 0 (modern flat design)
- **Shadows**: Theme-aware shadows from AppTheme

#### Typography
- **Title**: `textTheme.titleLarge` (18dp phone, 24dp tablet)
- **Message**: `textTheme.bodyMedium` (16dp)
- **Alignment**: Centered text for better readability
- **Font Weight**: SemiBold for titles, Normal for messages

#### Icons
- **Size**: 32dp
- **Circle Background**: Colored background with 10% opacity
- **Success**: Green (`AppTheme.emerald600`)
- **Error**: Red (`AppTheme.red600`)
- **Warning**: Amber (`AppTheme.amber600`)
- **Info**: Blue (`AppTheme.blue600`)
- **Confirmation**: Neutral or error color for destructive actions

### Theme Adaptiveness

All dialogs use theme-aware colors from `Theme.of(context).colorScheme`:

- `surface` - Dialog background
- `onSurface` - Primary text
- `primary` - Primary actions and branding
- `error` - Error states and destructive actions
- `secondary` - Secondary text and icons
- `tertiary` - Warning states

**Verified for**:
- ✅ Dark mode readability
- ✅ Light mode readability
- ✅ High contrast mode support

### Action Buttons

#### Phone Layout
- Full-width stacked buttons
- Vertical spacing between buttons

#### Tablet Layout
- Horizontal button alignment
- Right-aligned actions
- Compact horizontal spacing

#### Button Styles
- **Primary Button**: Filled style
- **Secondary Button**: Outlined style
- **Destructive Button**: Error color with filled style
- **Minimum Height**: 48dp (touch target compliance)

### Accessibility Features

- ✅ Semantic labels for all icons and buttons
- ✅ Screen-reader announcement on dialog open
- ✅ Focus trapped inside dialog
- ✅ Escape/back button dismiss support
- ✅ 48dp minimum touch targets
- ✅ Scalable text support (up to 200%)
- ✅ Proper barrier labels for screen readers
- ✅ High contrast color ratios

## Dialog Types & Usage

### SuccessDialog

**Purpose**: Positive feedback for successful operations

**Icon**: Green check circle

**Default Action**: "OK"

**Example Usage**:
```dart
await SuccessDialog.show(
  context: context,
  title: 'Moved to Trash',
  message: 'The deck was moved to Trash and can be restored later.',
);
```

**Use Cases**:
- Delete operations (with friendly "moved to trash" message)
- Backup creation
- Successful imports
- AI generation completion
- Settings changes

### ErrorDialog

**Purpose**: Error reporting with recovery options

**Icon**: Red alert circle

**Default Actions**: "Try Again" (primary), "Close" (secondary)

**Example Usage**:
```dart
await ErrorDialog.show(
  context: context,
  title: 'AI Limit Reached',
  message: 'You have reached today\'s AI generation limit.',
  primaryAction: 'Try Again',
  secondaryAction: 'Close',
);
```

**Use Cases**:
- AI quota exceeded
- Network errors
- Permission errors
- Storage errors
- Operation failures

### WarningDialog

**Purpose**: Confirm potentially risky actions

**Icon**: Amber warning triangle

**Default Actions**: "Confirm" (primary), "Cancel" (secondary)

**Example Usage**:
```dart
final confirmed = await WarningDialog.show(
  context: context,
  title: 'Delete Deck',
  message: 'This action cannot be undone.',
  confirmAction: 'Delete',
  cancelAction: 'Cancel',
);
if (confirmed == true) {
  // Proceed with deletion
}
```

**Use Cases**:
- Destructive actions
- Irreversible operations
- Data loss warnings
- Critical confirmations

### InfoDialog

**Purpose**: Informational messages and tips

**Icon**: Blue info circle

**Default Action**: "Got It"

**Example Usage**:
```dart
await InfoDialog.show(
  context: context,
  title: 'Study Tip',
  message: 'Review your flashcards daily for better retention.',
);
```

**Use Cases**:
- Feature introductions
- Study tips
- Help messages
- Educational content

### ConfirmationDialog

**Purpose**: Generic confirmations with destructive action support

**Icon**: Neutral help circle (or error icon for destructive)

**Default Actions**: "Confirm" (primary), "Cancel" (secondary)

**Example Usage**:
```dart
final confirmed = await ConfirmationDialog.show(
  context: context,
  title: 'Delete Deck',
  message: 'Are you sure you want to delete this deck?',
  confirmAction: 'Delete',
  cancelAction: 'Cancel',
  isDestructive: true,
);
if (confirmed == true) {
  // Proceed with deletion
}
```

**Use Cases**:
- Generic confirmations
- Destructive actions
- Critical decisions
- Override confirmations

### LoadingDialog

**Purpose**: Indicate long-running operations

**Icon**: Circular progress indicator (48dp)

**Default Behavior**: Non-dismissible

**Example Usage**:
```dart
final dialog = LoadingDialog.show(
  context: context,
  message: 'Generating questions...',
);

// Perform async operation
await someAsyncOperation();

// Dismiss when done
if (context.mounted) {
  dialog.dismiss();
}
```

**Use Cases**:
- AI generation
- Backup restore
- Import processing
- Delete operations
- File operations

## DialogService

The `DialogService` provides a centralized API for showing dialogs with educational-friendly error messages.

### Methods

```dart
// Success dialog
DialogService.showSuccess(context, message, {title, onAcknowledge})

// Error dialog
DialogService.showError(context, message, {title, onAcknowledge, primaryAction, secondaryAction})

// Warning dialog (returns bool?)
DialogService.showWarning(context, message, {title, confirmAction, cancelAction, onConfirm, onCancel})

// Info dialog
DialogService.showInfo(context, message, {title, onAcknowledge})

// Confirmation dialog (returns bool?)
DialogService.showConfirmation(context, message, {title, confirmAction, cancelAction, isDestructive, onConfirm, onCancel})

// Loading dialog (returns controller)
DialogService.showLoading(context, {message, barrierDismissible})

// Friendly error messages
DialogService.showFriendlyError(context, technicalMessage, {title, onAcknowledge})
DialogService.getFriendlyErrorMessage(technicalMessage)
```

### Educational-Friendly Error Messages

The DialogService automatically converts technical error messages into user-friendly, educational copy:

| Technical Error | Friendly Message |
|----------------|------------------|
| `PlatformException(exact alarm not permitted)` | "Study reminders are not available on this device right now." |
| `Token limit exceeded` | "You have reached today's AI generation limit." |
| `No overlay widget found` | "Something went wrong while showing this message. Please try again." |
| `Network error` | "Please check your internet connection and try again." |
| `Permission denied` | "The app needs permission to complete this action." |
| `Storage full` | "Please check your available storage and try again." |

## Integration Guidelines

### Basic Usage

1. **Import the dialog service**:
```dart
import '../../core/services/dialog_service.dart';
```

2. **Show a dialog**:
```dart
await DialogService.showSuccess(
  context,
  'Operation completed successfully.',
  title: 'Success',
);
```

3. **Check context before showing**:
```dart
if (context.mounted) {
  await DialogService.showError(context, 'Something went wrong');
}
```

### Replacing Existing Dialogs

#### Old AlertDialog Pattern
```dart
await showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Error'),
    content: Text('Something went wrong'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);
```

#### New DialogService Pattern
```dart
await DialogService.showError(
  context,
  'Something went wrong',
  title: 'Error',
);
```

### Custom Dialog Content

For dialogs with custom content (like forms), use the AppDialog base:

```dart
import '../../shared/widgets/dialogs/dialogs.dart';

await AppDialog.show(
  context: context,
  title: 'Custom Dialog',
  message: 'Dialog with custom content',
  icon: Icons.custom_icon,
  iconColor: Colors.blue,
  actions: [
    ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Action'),
    ),
  ],
);
```

## Success Flow Examples

### Delete Deck
```dart
await DialogService.showSuccess(
  context,
  'The deck was moved to Trash and can be restored later.',
  title: 'Moved to Trash',
);
```

### Backup Export
```dart
await DialogService.showSuccess(
  context,
  'Backup "backup_name" was created successfully.',
  title: 'Backup Created',
);
```

### AI Generation
```dart
await DialogService.showSuccess(
  context,
  'Your questions were generated successfully.',
  title: 'Questions Ready',
);
```

## Error Flow Examples

### AI Quota
```dart
await DialogService.showQuotaExceeded(context);
// Shows: "AI Limit Reached" with friendly quota message
```

### Backup Failure
```dart
await DialogService.showFriendlyError(
  context,
  'Failed to create backup: $error',
  title: 'Backup Failed',
);
// Converts technical errors to friendly messages
```

### Restore Failure
```dart
await DialogService.showError(
  context,
  'The selected backup file is invalid.',
  title: 'Restore Failed',
);
```

## QA Checklist

### Visual Design
- ✅ Dialog centered on phone
- ✅ Dialog centered on tablet
- ✅ Dark mode correct colors
- ✅ Light mode correct colors
- ✅ No overflow with long messages
- ✅ Buttons always visible
- ✅ Consistent visual style

### Functionality
- ✅ Back button works
- ✅ No overlay crashes
- ✅ Smooth animation (200ms)
- ✅ Barrier dismissible where appropriate
- ✅ Loading dialog non-dismissible

### Accessibility
- ✅ Semantic labels present
- ✅ Screen reader announcements
- ✅ Focus management
- ✅ 48dp touch targets
- ✅ High contrast ratios
- ✅ Text scaling support

### Responsiveness
- ✅ Phone layout (90% width)
- ✅ Tablet layout (420-520dp)
- ✅ Safe area handling
- ✅ Landscape orientation
- ✅ Different screen sizes

## Migration Status

### Completed Refactoring
- ✅ `DialogService` - Updated to use new dialog components
- ✅ `ConfirmationDialog` - Wrapped to use new system
- ✅ `RestoreItemDialog` - Refactored to new system
- ✅ `CreateBackupDialog` - Refactored with new styling
- ✅ `DeleteFlashcardDialog` - Refactored with educational copy
- ✅ `PauseDialog` - Updated with new styling
- ✅ `SubmitConfirmationDialog` - Updated with new styling
- ✅ `TrashScreen` - Updated error messages to use friendly copy

### Backward Compatibility
- ✅ Existing `ConfirmationDialog.show()` calls work without changes
- ✅ Existing `DialogService` API maintained
- ✅ Custom dialogs can still use AlertDialog directly if needed

### Remaining Work
- ⏳ Update remaining feature screens to use friendly error messages
- ⏳ Replace remaining AlertDialog usages with DialogService
- ⏳ Update success messages throughout the app with educational copy
- ⏳ Add loading dialogs to long-running operations

## Performance Considerations

- Dialogs use `showGeneralDialog` for better performance than `showDialog`
- Animations are optimized with Tween and CurvedAnimation
- No global BuildContext storage - prevents memory leaks
- Context mounted checks prevent crashes on async operations
- ConstrainedBox prevents unnecessary layout calculations

## Future Enhancements

- Add animation curve customization
- Support for custom dialog animations
- Dialog queue management for multiple dialogs
- Dialog history/back stack
- Custom icon support in DialogService
- Localization support for dialog messages
- Dialog analytics and usage tracking

## Conclusion

The new dialog system provides a modern, accessible, and consistent user experience across QuizSnap. All dialogs are centered, animated, theme-aware, and use educational-friendly copy to create a calm, confidence-building experience for students.

The system is fully integrated with the existing AppTheme design system and maintains backward compatibility while providing a clear migration path for existing code.
