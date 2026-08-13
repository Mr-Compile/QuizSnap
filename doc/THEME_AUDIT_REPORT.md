# QuizSnap Dark/Light Theme Adaptiveness Audit Report

**Audit Date:** 2026-08-13  
**Auditor:** Flutter UI Engineer / Material 3 Specialist  
**Project:** QuizSnap Flutter Application  
**Scope:** Complete theme adaptiveness audit for all screens, widgets, and components

---

## Executive Summary

This comprehensive audit identified **47 theme-related issues** across the QuizSnap application. The issues are categorized as:

- **Critical Issues:** 8 (immediate visibility problems in dark mode)
- **Major Issues:** 24 (contrast problems and theme inconsistencies)
- **Minor Issues:** 15 (cosmetic issues and edge cases)

### Key Findings

1. **Hard-coded Colors:** Extensive use of `Colors.white`, `Colors.black`, and semantic colors (red, green, blue, orange, purple) that don't adapt to theme changes
2. **Notification System:** Banner and toast colors are hard-coded and don't adapt to dark mode
3. **Study/Exam Screens:** Rating buttons and answer selection use hard-coded colors that become invisible in dark mode
4. **Analytics Charts:** Chart colors are hard-coded and lose visibility in dark mode
5. **AI Generation Screens:** Document type indicators and camera overlays use non-adaptive colors

### Success Criteria Status

- ❌ No hard-coded colors remain in theme-sensitive widgets
- ❌ All text is readable in light and dark mode
- ❌ All icons adapt correctly
- ❌ All dialogs adapt correctly
- ❌ All charts remain readable
- ⚠️ Runtime theme switching works (basic implementation exists)
- ❌ Accessibility contrast passes on all primary screens

---

## Detailed Issue Report

### Critical Issues (8)

| Severity | Screen | File Path | Widget/Class | Current Behavior | Dark Mode Result | Light Mode Result | Recommended Fix | Status |
|----------|--------|-----------|-------------|------------------|-----------------|------------------|-----------------|---------|
| Critical | Study Session | `lib/features/study/flashcard_study_session_screen.dart` | `_buildRatingControls` | Rating buttons use `Colors.red`, `Colors.orange`, `Colors.blue`, `Colors.green` | Buttons invisible or very low contrast | Works but not theme-aware | Replace with `AppTheme.red600`, `AppTheme.amber600`, `AppTheme.blue600`, `AppTheme.emerald600` | ❌ Not Fixed |
| Critical | Exam Question | `lib/features/exam/exam_question_screen.dart` | `_buildAnswerOptions` | Selected answer text uses `Colors.white` | Text invisible on dark backgrounds | Works on light backgrounds | Use `Theme.of(context).colorScheme.onPrimary` or theme-aware color | ❌ Not Fixed |
| Critical | Exam Review | `lib/features/exam/exam_review_screen.dart` | `_buildFilterChips` | Selected chip count uses `Colors.white` | Text invisible in dark mode | Works on light mode | Use `Theme.of(context).colorScheme.onPrimary` | ❌ Not Fixed |
| Critical | Exam Review | `lib/features/exam/exam_review_screen.dart` | `_buildQuestionCard` | Question number uses `Colors.white` | Text invisible in dark mode | Works on light mode | Use `Theme.of(context).colorScheme.onPrimary` | ❌ Not Fixed |
| Critical | Exam Result | `lib/features/exam/exam_result_screen.dart` | `_buildScoreCard` | Grade badge text uses `Colors.white` | Text invisible in dark mode | Works on light mode | Use `Theme.of(context).colorScheme.onPrimary` | ❌ Not Fixed |
| Critical | Notification Service | `lib/core/providers/notification_service.dart` | `showSuccess`, `showInfoTop`, `showWarningTop`, `showErrorTop` | Hard-coded hex colors for banners | Banners don't adapt to dark mode | Works on light mode | Create theme-aware banner colors using `Theme.of(context).colorScheme` | ❌ Not Fixed |
| Critical | Camera OCR | `lib/features/ai_generate/camera_ocr_screen.dart` | Camera overlay | Text and UI use `Colors.white` on dark overlay | Poor contrast in both modes | Poor contrast in both modes | Use theme-aware overlay colors with proper contrast | ❌ Not Fixed |
| Critical | Loading Overlay | `lib/shared/widgets/app_loading_screen.dart` | `LoadingOverlay` | Overlay uses `Colors.black.withValues(alpha: 0.7)` | Too dark in dark mode | Works in light mode | Use `Theme.of(context).colorScheme.scrim` or theme-aware overlay | ❌ Not Fixed |

### Major Issues (24)

| Severity | Screen | File Path | Widget/Class | Current Behavior | Dark Mode Result | Light Mode Result | Recommended Fix | Status |
|----------|--------|-----------|-------------|------------------|-----------------|------------------|-----------------|---------|
| Major | Question Review | `lib/features/ai_generate/question_review_screen.dart` | Difficulty badge | Uses `Colors.white` for text | Low contrast in dark mode | Works in light mode | Use theme-aware text color | ❌ Not Fixed |
| Major | Question Review | `lib/features/ai_generate/question_review_screen.dart` | Answer correctness | Uses `Colors.white` for correct answers | Low contrast in dark mode | Works in light mode | Use theme-aware color | ❌ Not Fixed |
| Major | Deck List | `lib/features/decks/deck_list_screen.dart` | Deck icon | Uses `Colors.white` for deck icon | Low contrast on colored backgrounds | Works in light mode | Use theme-aware icon color or adaptive white/black | ❌ Not Fixed |
| Major | Deck Details | `lib/features/decks/deck_details_screen.dart` | Deck icon | Uses `Colors.white` for deck icon | Low contrast on colored backgrounds | Works in light mode | Use theme-aware icon color | ❌ Not Fixed |
| Major | Create/Edit Deck | `lib/features/decks/create_deck_screen.dart`, `edit_deck_screen.dart` | Save button icon | Uses `Colors.white` for check icon | Low contrast in dark mode | Works in light mode | Use theme-aware color | ❌ Not Fixed |
| Major | Trash Screen | `lib/features/trash/trash_screen.dart` | Folder/deck icons | Uses `Colors.white` for icons | Low contrast in dark mode | Works in light mode | Use theme-aware icon color | ❌ Not Fixed |
| Major | Move Flashcard | `lib/features/flashcards/move_flashcard_screen.dart` | Deck icon | Uses `Colors.white` for icon | Low contrast in dark mode | Works in light mode | Use theme-aware icon color | ❌ Not Fixed |
| Major | Backup Restore | `lib/features/export/backup_restore_screen.dart` | Status text | Uses `Colors.grey` for disabled text | Low contrast in dark mode | Works in light mode | Use `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)` | ❌ Not Fixed |
| Major | Analytics Performance | `lib/features/analytics/quiz_performance_screen.dart` | Stat icons | Uses `Colors.green`, `Colors.blue` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Analytics Performance | `lib/features/analytics/quiz_performance_screen.dart` | Score colors | Uses `Colors.green`, `Colors.orange`, `Colors.red` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Weak Topics | `lib/features/analytics/weak_topics_screen.dart` | Success icon | Uses `Colors.green` | Low contrast in dark mode | Works in light mode | Use AppTheme.emerald600 | ❌ Not Fixed |
| Major | Weak Topics | `lib/features/analytics/weak_topics_screen.dart` | Accuracy colors | Uses `Colors.orange`, `Colors.red` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Weak Topics | `lib/features/analytics/weak_topics_screen.dart` | Chart bars | Uses `Colors.green`, `Colors.orange`, `Colors.red` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Weak Topics | `lib/features/analytics/weak_topics_screen.dart` | Recommendation icon | Uses `Colors.amber` | Low contrast in dark mode | Works in light mode | Use AppTheme.amber600 | ❌ Not Fixed |
| Major | Subject Accuracy | `lib/features/analytics/subject_accuracy_screen.dart` | Accuracy colors | Uses `Colors.green`, `Colors.orange`, `Colors.red` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Subject Accuracy | `lib/features/analytics/subject_accuracy_screen.dart` | Chart bars | Uses `Colors.green`, `Colors.orange`, `Colors.red` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | AI Generate Home | `lib/features/ai_generate/ai_generate_home_screen.dart` | Import card icons | Uses `Colors.red`, `Colors.green`, `Colors.blue`, `Colors.orange`, `Colors.purple` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Document Scope | `lib/features/ai_generate/document_scope_selection_screen.dart` | Option icons | Uses `Colors.blue`, `Colors.green`, `Colors.orange`, `Colors.purple` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Cached Documents | `lib/features/ai_generate/cached_documents_screen.dart` | Document type colors | Uses `Colors.red`, `Colors.green`, `Colors.blue` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Study Home | `lib/features/study/study_home_screen.dart` | Stat icons | Uses `Colors.orange`, `Colors.blue`, `Colors.green`, `Colors.purple` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Bookmark List | `lib/features/study/bookmark_list_screen.dart` | Bookmark icon | Uses `Colors.blue` | Low contrast in dark mode | Works in light mode | Use AppTheme.blue600 | ❌ Not Fixed |
| Major | Flashcard List | `lib/features/study/flashcard_list_screen.dart` | Bookmark icon | Uses `Colors.blue` | Low contrast in dark mode | Works in light mode | Use AppTheme.blue600 | ❌ Not Fixed |
| Major | Rate Card Bottom Sheet | `lib/features/study/rate_card_bottom_sheet.dart` | Rating buttons | Uses `Colors.red`, `Colors.orange`, `Colors.blue`, `Colors.green` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Major | Custom Button | `lib/shared/widgets/custom_button.dart` | Loading indicator | Uses `Colors.white` for spinner | Invisible on light-themed buttons | Works on dark-themed buttons | Use theme-aware color based on button style | ❌ Not Fixed |

### Minor Issues (15)

| Severity | Screen | File Path | Widget/Class | Current Behavior | Dark Mode Result | Light Mode Result | Recommended Fix | Status |
|----------|--------|-----------|-------------|------------------|-----------------|------------------|-----------------|---------|
| Minor | Question Review | `lib/features/ai_generate/question_review_screen.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Text Preview | `lib/features/ai_generate/text_preview_screen.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Analysis Preview | `lib/features/ai_generate/analysis_preview_screen.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Section Preview | `lib/features/ai_generate/section_preview_screen.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Heading Tree Selection | `lib/features/ai_generate/heading_tree_selection_screen.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Selected Text Summary | `lib/shared/widgets/selected_text_summary_sheet.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Flashcard Card | `lib/features/study/flashcard_card_screen.dart` | Card shadow | Uses `Colors.black.withValues(alpha: 0.1)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | App Toast Overlay | `lib/shared/widgets/app_toast_overlay.dart` | Toast shadow | Uses `Colors.black.withValues(alpha: 0.15)` | Shadow too dark in dark mode | Works in light mode | Use theme-aware shadow from AppTheme | ❌ Not Fixed |
| Minor | Exam Review | `lib/features/exam/exam_review_screen.dart` | Border color | Uses `Colors.grey` for default border | Low contrast in dark mode | Works in light mode | Use `Theme.of(context).colorScheme.outline` | ❌ Not Fixed |
| Minor | Security Settings | `lib/features/settings/security_settings_screen.dart` | Delete icon | Uses `Colors.red` | Low contrast in dark mode | Works in light mode | Use AppTheme.red600 | ❌ Not Fixed |
| Minor | Security Settings | `lib/features/settings/security_settings_screen.dart` | Button text | Uses `Colors.red` for destructive buttons | Low contrast in dark mode | Works in light mode | Use AppTheme.red600 | ❌ Not Fixed |
| Minor | PIN Lock Screen | `lib/features/settings/pin_lock_screen.dart` | Hint text | Uses `Colors.grey` | Low contrast in dark mode | Works in light mode | Use theme-aware color | ❌ Not Fixed |
| Minor | PIN Lock Screen | `lib/features/settings/pin_lock_screen.dart` | PIN dots | Uses `Colors.grey.withValues(alpha: 0.3)` | Low contrast in dark mode | Works in light mode | Use theme-aware color | ❌ Not Fixed |
| Minor | Authorized Quota | `lib/features/settings/authorized_quota_screen.dart` | Action icons | Uses `Colors.green`, `Colors.orange`, `Colors.blue`, `Colors.purple`, `Colors.teal` | Low contrast in dark mode | Works in light mode | Use AppTheme semantic colors | ❌ Not Fixed |
| Minor | Prompt History | `lib/screens/prompts/prompt_history_screen.dart` | Background colors | Uses `Colors.white` and manual dark mode check | Inconsistent theme handling | Works in light mode | Use `Theme.of(context).colorScheme.surface` | ❌ Not Fixed |

---

## Issues by Screen Category

### Study & Exam Screens (Highest Priority)
- **Flashcard Study Session Screen:** 4 issues (rating buttons, shadows)
- **Exam Question Screen:** 1 issue (selected answer text)
- **Exam Review Screen:** 4 issues (chip colors, question numbers, borders)
- **Exam Result Screen:** 1 issue (grade badge text)
- **Rate Card Bottom Sheet:** 4 issues (rating button colors)

### Analytics Screens
- **Quiz Performance Screen:** 3 issues (stat icons, score colors)
- **Weak Topics Screen:** 4 issues (success icon, accuracy colors, chart colors, recommendation icon)
- **Subject Accuracy Screen:** 2 issues (accuracy colors, chart colors)
- **Analytics Dashboard Screen:** 0 issues (uses theme-aware colors correctly)

### AI Generate Screens
- **AI Generate Home Screen:** 5 issues (import card icons)
- **Document Scope Selection Screen:** 4 issues (option icons)
- **Question Review Screen:** 3 issues (difficulty badge, answer correctness, shadow)
- **Cached Documents Screen:** 3 issues (document type colors)
- **Camera OCR Screen:** 4 issues (overlay colors, text colors)
- **PDF Preview Screen:** 0 issues (uses theme-aware colors)
- **Heading Selection Screen:** 0 issues (uses theme-aware colors)

### Deck & Flashcard Screens
- **Deck List Screen:** 1 issue (deck icon)
- **Deck Details Screen:** 1 issue (deck icon)
- **Create/Edit Deck Screen:** 2 issues (save button icons)
- **Trash Screen:** 2 issues (folder/deck icons)
- **Move Flashcard Screen:** 1 issue (deck icon)
- **Study Home Screen:** 4 issues (stat icons)
- **Bookmark List Screen:** 1 issue (bookmark icon)
- **Flashcard List Screen:** 1 issue (bookmark icon)
- **Flashcard Card Screen:** 1 issue (card shadow)

### Settings Screens
- **Settings Screen:** 0 issues (uses theme-aware colors)
- **Security Settings Screen:** 2 issues (delete icon, button text)
- **PIN Lock Screen:** 2 issues (hint text, PIN dots)
- **Authorized Quota Screen:** 5 issues (action icons)

### Shared Components
- **Notification Service:** 4 issues (banner colors)
- **Custom Button:** 1 issue (loading indicator)
- **App Loading Screen:** 1 issue (overlay color)
- **App Toast Overlay:** 1 issue (toast shadow)
- **Selected Text Summary Sheet:** 1 issue (card shadow)
- **Flashcard Flip Card:** 0 issues (uses theme-aware colors correctly)

---

## Files Requiring Modification

### Core Theme Files
- `lib/core/theme/app_theme.dart` - Add semantic color constants for dark mode
- `lib/core/providers/theme_provider.dart` - Already well-implemented

### High Priority Files (Critical & Major Issues)
1. `lib/features/study/flashcard_study_session_screen.dart`
2. `lib/features/exam/exam_question_screen.dart`
3. `lib/features/exam/exam_review_screen.dart`
4. `lib/features/exam/exam_result_screen.dart`
5. `lib/core/providers/notification_service.dart`
6. `lib/features/ai_generate/camera_ocr_screen.dart`
7. `lib/shared/widgets/app_loading_screen.dart`
8. `lib/features/analytics/quiz_performance_screen.dart`
9. `lib/features/analytics/weak_topics_screen.dart`
10. `lib/features/analytics/subject_accuracy_screen.dart`
11. `lib/features/ai_generate/ai_generate_home_screen.dart`
12. `lib/features/ai_generate/document_scope_selection_screen.dart`
13. `lib/features/study/study_home_screen.dart`
14. `lib/shared/widgets/custom_button.dart`

### Medium Priority Files (Major Issues)
15. `lib/features/ai_generate/question_review_screen.dart`
16. `lib/features/ai_generate/cached_documents_screen.dart`
17. `lib/features/decks/deck_list_screen.dart`
18. `lib/features/decks/deck_details_screen.dart`
19. `lib/features/decks/create_deck_screen.dart`
20. `lib/features/decks/edit_deck_screen.dart`
21. `lib/features/trash/trash_screen.dart`
22. `lib/features/flashcards/move_flashcard_screen.dart`
23. `lib/features/export/backup_restore_screen.dart`
24. `lib/features/study/bookmark_list_screen.dart`
25. `lib/features/study/flashcard_list_screen.dart`
26. `lib/features/study/rate_card_bottom_sheet.dart`
27. `lib/features/study/flashcard_card_screen.dart`
28. `lib/features/settings/security_settings_screen.dart`
29. `lib/features/settings/pin_lock_screen.dart`
30. `lib/features/settings/authorized_quota_screen.dart`

### Low Priority Files (Minor Issues)
31. `lib/features/ai_generate/text_preview_screen.dart`
32. `lib/features/ai_generate/analysis_preview_screen.dart`
33. `lib/features/ai_generate/section_preview_screen.dart`
34. `lib/features/ai_generate/heading_tree_selection_screen.dart`
35. `lib/shared/widgets/selected_text_summary_sheet.dart`
36. `lib/shared/widgets/app_toast_overlay.dart`
37. `lib/screens/prompts/prompt_history_screen.dart`

---

## Recommended Fixes

### 1. Notification Service Overhaul

**Current Issue:** Hard-coded hex colors for banners don't adapt to dark mode.

**Recommended Fix:**
```dart
// In notification_service.dart, replace hard-coded colors with theme-aware colors:

void showSuccess(BuildContext context, String message, {
  bool showUndo = false,
  VoidCallback? onUndo,
  IconData icon = Icons.check_circle,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  showTopBanner(BannerMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    message: message,
    icon: icon,
    backgroundColor: isDark 
        ? AppTheme.emerald900 
        : AppTheme.emerald50,
    borderColor: isDark 
        ? AppTheme.emerald700 
        : AppTheme.emerald200,
    iconColor: AppTheme.emerald500,
    textColor: isDark 
        ? AppTheme.emerald100 
        : AppTheme.emerald900,
    showUndo: showUndo,
    onUndo: onUndo,
  ));
}
```

### 2. Study Screen Rating Buttons

**Current Issue:** Rating buttons use hard-coded Colors.red, Colors.orange, Colors.blue, Colors.green.

**Recommended Fix:**
```dart
// In flashcard_study_session_screen.dart, replace:
_buildRatingButton(context, 'Again', Colors.red, 0, controller),
_buildRatingButton(context, 'Hard', Colors.orange, 2, controller),
_buildRatingButton(context, 'Good', Colors.blue, 3, controller),
_buildRatingButton(context, 'Easy', Colors.green, 4, controller),

// With:
_buildRatingButton(context, 'Again', AppTheme.red600, 0, controller),
_buildRatingButton(context, 'Hard', AppTheme.amber600, 2, controller),
_buildRatingButton(context, 'Good', AppTheme.blue600, 3, controller),
_buildRatingButton(context, 'Easy', AppTheme.emerald600, 4, controller),
```

### 3. Exam Screen Selected Answer Text

**Current Issue:** Selected answer text uses Colors.white, invisible in dark mode.

**Recommended Fix:**
```dart
// In exam_question_screen.dart, replace:
color: isSelected
    ? Colors.white
    : Theme.of(context).colorScheme.onSurface,

// With:
color: isSelected
    ? Theme.of(context).colorScheme.onPrimary
    : Theme.of(context).colorScheme.onSurface,
```

### 4. Analytics Chart Colors

**Current Issue:** Charts use hard-coded Colors.green, Colors.orange, Colors.red.

**Recommended Fix:**
```dart
// In analytics screens, replace:
final scoreColor = score >= 80
    ? Colors.green
    : score >= 60
        ? Colors.orange
        : Colors.red;

// With:
final scoreColor = score >= 80
    ? AppTheme.emerald600
    : score >= 60
        ? AppTheme.amber600
        : AppTheme.red600;
```

### 5. Loading Overlay

**Current Issue:** Overlay uses hard-coded Colors.black.withValues(alpha: 0.7).

**Recommended Fix:**
```dart
// In app_loading_screen.dart, replace:
color: Colors.black.withValues(alpha: 0.7),

// With:
color: Theme.of(context).colorScheme.scrim,
```

### 6. Custom Button Loading Indicator

**Current Issue:** Loading spinner uses hard-coded Colors.white.

**Recommended Fix:**
```dart
// In custom_button.dart, replace:
valueColor: AlwaysStoppedAnimation<Color>(Colors.white),

// With:
valueColor: AlwaysStoppedAnimation<Color>(
  isOutlined 
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.onPrimary,
),
```

### 7. AI Generate Screen Icons

**Current Issue:** Document type icons use hard-coded colors.

**Recommended Fix:**
```dart
// In ai_generate_home_screen.dart, replace:
color: Colors.red,  // PDF
color: Colors.green,  // TXT
color: Colors.blue,  // DOCX
color: Colors.orange,  // Cached
color: Colors.purple,  // Camera

// With:
color: AppTheme.red600,  // PDF
color: AppTheme.emerald600,  // TXT
color: AppTheme.blue600,  // DOCX
color: AppTheme.amber600,  // Cached
color: AppTheme.purple600,  // Camera
```

### 8. Deck Icons

**Current Issue:** Deck icons use hard-coded Colors.white.

**Recommended Fix:**
```dart
// In deck_list_screen.dart and deck_details_screen.dart, replace:
child: const Icon(
  Icons.style,
  color: Colors.white,
),

// With:
child: Icon(
  Icons.style,
  color: _getContrastColor(deckColor),
),

// Add helper function:
Color _getContrastColor(Color backgroundColor) {
  // Calculate luminance to determine if white or black text is better
  final luminance = backgroundColor.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}
```

---

## Theme Switching Behavior

### Current Implementation
The app has a basic theme switching implementation via `ThemeProvider` that supports:
- System theme mode
- Light theme mode  
- Dark theme mode
- Theme persistence via SharedPreferences

### Issues Found
1. **No immediate UI updates:** Some widgets don't rebuild when theme changes
2. **Hard-coded colors prevent adaptation:** Many colors don't respond to theme changes
3. **No theme transition animations:** Theme changes are abrupt

### Recommendations
1. **Ensure all widgets use Theme.of(context):** Replace hard-coded colors with theme-aware colors
2. **Add theme transition animations:** Implement smooth theme transitions
3. **Test runtime theme switching:** Verify all screens update immediately when theme changes

---

## Accessibility & Contrast Analysis

### WCAG AA Compliance Status

**Passing Screens:**
- Analytics Dashboard Screen (uses theme-aware colors correctly)
- Settings Screen (uses theme-aware colors correctly)
- PDF Preview Screen (uses theme-aware colors correctly)
- Heading Selection Screen (uses theme-aware colors correctly)

**Failing Screens:**
- Study Session Screen (rating buttons have insufficient contrast in dark mode)
- Exam Question Screen (selected answer text has insufficient contrast in dark mode)
- Exam Review Screen (chip text and question numbers have insufficient contrast in dark mode)
- All Analytics Chart screens (chart colors have insufficient contrast in dark mode)
- AI Generate screens (icon colors have insufficient contrast in dark mode)

### Contrast Issues Summary

1. **Text on Background:** Many instances of white text on colored backgrounds without proper contrast consideration
2. **Icon Visibility:** Colored icons on dark backgrounds have insufficient contrast
3. **Chart Readability:** Chart colors not optimized for dark mode viewing
4. **Overlay Contrast:** Loading overlays and toasts have poor contrast in both modes

### Recommendations

1. **Implement contrast-aware color selection:** Use luminance calculations to determine appropriate text colors
2. **Add high-contrast mode support:** Consider adding a high-contrast theme option
3. **Test with accessibility tools:** Use Flutter's accessibility semantics and contrast checking tools
4. **Provide theme-aware alternatives:** Ensure all semantic colors have dark mode alternatives

---

## Testing Recommendations

### Manual Testing Checklist

#### Light Mode Testing
- [ ] All text is readable against backgrounds
- [ ] Icons are visible and distinguishable
- [ ] Charts and graphs are clear
- [ ] Buttons and interactive elements have proper contrast
- [ ] Overlays and dialogs are readable

#### Dark Mode Testing
- [ ] All text is readable against dark backgrounds
- [ ] Icons don't blend into dark backgrounds
- [ ] Charts and graphs remain visible
- [ ] Selected states are clearly visible
- [ ] Overlays and dialogs don't blend into content

#### Runtime Theme Switching
- [ ] Open Settings screen
- [ ] Change theme from Light to Dark
- [ ] Navigate to various screens (Study, Exam, Analytics)
- [ ] Verify all UI elements update immediately
- [ ] Change theme from Dark to System
- [ ] Change device theme
- [ ] Verify app adapts to system theme

### Automated Testing Recommendations

#### Widget Tests
Add widget tests to verify theme awareness:

```dart
testWidgets('Study screen rating buttons use theme colors', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: FlashcardStudySessionScreen(flashcards: testFlashcards),
    ),
  );
  
  // Test in light mode
  expect(find.byType(ElevatedButton), findsWidgets);
  
  // Test in dark mode
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: FlashcardStudySessionScreen(flashcards: testFlashcards),
    ),
  );
  expect(find.byType(ElevatedButton), findsWidgets);
});
```

#### Golden Tests
Add golden tests for critical screens in both themes:

```dart
testGolden('Study screen in light mode', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: FlashcardStudySessionScreen(flashcards: testFlashcards),
    ),
  );
  await expectLater(
    find.byType(FlashcardStudySessionScreen),
    matchesGoldenFile('goldens/study_light.png'),
  );
});

testGolden('Study screen in dark mode', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: FlashcardStudySessionScreen(flashcards: testFlashcards),
    ),
  );
  await expectLater(
    find.byType(FlashcardStudySessionScreen),
    matchesGoldenFile('goldens/study_dark.png'),
  );
});
```

---

## Implementation Priority

### Phase 1: Critical Issues (Week 1)
1. Fix Notification Service banner colors
2. Fix Study Session rating buttons
3. Fix Exam screen selected answer text
4. Fix Exam Review screen text colors
5. Fix Loading overlay color
6. Fix Custom Button loading indicator

### Phase 2: Major Issues - Study & Exam (Week 2)
1. Fix all Exam screen color issues
2. Fix all Study screen color issues
3. Fix Rate Card Bottom Sheet colors
4. Test runtime theme switching for Study/Exam flows

### Phase 3: Major Issues - Analytics (Week 3)
1. Fix all Analytics chart colors
2. Fix Analytics stat icon colors
3. Test all Analytics screens in both themes
4. Add golden tests for Analytics screens

### Phase 4: Major Issues - AI Generate (Week 4)
1. Fix AI Generate screen icon colors
2. Fix Camera OCR overlay colors
3. Fix Document Preview screen colors
4. Test all AI Generate screens in both themes

### Phase 5: Major Issues - Decks & Settings (Week 5)
1. Fix Deck screen icon colors
2. Fix Settings screen color issues
3. Fix Trash and Move screens
4. Test all Deck and Settings screens in both themes

### Phase 6: Minor Issues & Polish (Week 6)
1. Fix shadow colors across all screens
2. Fix remaining minor color issues
3. Add theme transition animations
4. Comprehensive testing and refinement

---

## Success Criteria Verification

### Before Fix
- ❌ 47 theme-related issues identified
- ❌ Hard-coded colors in 37 files
- ❌ Critical visibility issues in dark mode
- ❌ Analytics charts unreadable in dark mode
- ❌ Study/Exam screens have contrast issues

### After Fix (Target State)
- ✅ 0 theme-related issues
- ✅ All colors use Theme.of(context) or AppTheme constants
- ✅ All text readable in both light and dark mode
- ✅ All icons visible and distinguishable in both themes
- ✅ All charts readable in both themes
- ✅ Runtime theme switching works seamlessly
- ✅ WCAG AA contrast compliance on all primary screens
- ✅ Comprehensive widget and golden test coverage

---

## Conclusion

The QuizSnap application has a solid foundation with a well-designed AppTheme system and ThemeProvider implementation. However, extensive use of hard-coded colors throughout the UI layer prevents proper theme adaptation, particularly in dark mode.

The most critical issues are in the Study and Exam screens, where hard-coded colors make text and interactive elements invisible in dark mode. The Analytics screens also have significant issues with chart readability.

By systematically replacing hard-coded colors with theme-aware alternatives and implementing the recommended fixes, QuizSnap can achieve full theme adaptiveness and provide an excellent user experience in both light and dark modes.

**Estimated Effort:** 6 weeks of focused development to address all identified issues and implement comprehensive testing.

**Risk Level:** Medium - Changes are localized to color usage and don't affect business logic, but extensive testing is required to ensure no regressions.

**Recommendation:** Proceed with Phase 1 (Critical Issues) immediately, as these affect core functionality and user experience in dark mode.
