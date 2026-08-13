# QuizSnap Dark/Light Theme QA Checklist

**Purpose:** This checklist provides a practical guide for verifying that QuizSnap is fully adaptive to dark and light themes after implementing the fixes identified in the Theme Audit Report.

**Last Updated:** 2026-08-13  
**Version:** 1.0

---

## Pre-Testing Setup

### Environment Setup
- [ ] Test on both iOS and Android devices
- [ ] Test on different screen sizes (phone, tablet)
- [ ] Enable developer options to force theme changes
- [ ] Ensure app is built with latest Flutter version

### Theme Mode Testing
- [ ] Light Mode: Set device/system to light theme
- [ ] Dark Mode: Set device/system to dark theme  
- [ ] System Mode: Set app to "System" theme and switch device theme
- [ ] App Theme Mode: Set app to "Light" and "Dark" independently of system

---

## Critical Screen Testing

### 1. Study Session Screen
**File:** `lib/features/study/flashcard_study_session_screen.dart`

#### Light Mode Checks
- [ ] Flashcard front text is readable
- [ ] Flashcard back text is readable when revealed
- [ ] Rating buttons (Again, Hard, Good, Easy) have distinct colors
- [ ] Rating button text is readable against button background
- [ ] Progress bar is visible
- [ ] Bookmark icon is visible and distinguishable
- [ ] Navigation buttons (Previous, Next) are visible

#### Dark Mode Checks
- [ ] Flashcard front text is readable against dark background
- [ ] Flashcard back text is readable when revealed
- [ ] Rating buttons maintain contrast in dark mode
- [ ] Rating button text is readable (no white-on-white issues)
- [ ] Progress bar is visible against dark background
- [ ] Bookmark icon contrasts properly with dark background
- [ ] Navigation buttons are visible and distinguishable

#### Theme Switching
- [ ] Switch from light to dark while studying - UI updates immediately
- [ ] Switch from dark to light while studying - UI updates immediately
- [ ] No manual refresh required

---

### 2. Exam Question Screen
**File:** `lib/features/exam/exam_question_screen.dart`

#### Light Mode Checks
- [ ] Question text is readable
- [ ] Answer options are clearly visible
- [ ] Selected answer has clear visual feedback
- [ ] Selected answer text (A, B, C, D) is readable
- [ ] Timer display is visible
- [ ] Progress bar is visible
- [ ] Navigation buttons are visible

#### Dark Mode Checks
- [ ] Question text is readable against dark background
- [ ] Answer options maintain contrast
- [ ] Selected answer has clear visual feedback in dark mode
- [ ] Selected answer text is readable (no white-on-white)
- [ ] Timer display contrasts properly
- [ ] Progress bar is visible against dark background
- [ ] Navigation buttons are visible and distinguishable

#### Theme Switching
- [ ] Switch themes during exam - UI updates immediately
- [ ] Selected answer state is preserved during theme switch
- [ ] Timer continues to function correctly

---

### 3. Exam Review Screen
**File:** `lib/features/exam/exam_review_screen.dart`

#### Light Mode Checks
- [ ] Filter chips (All, Correct, Incorrect) are visible
- [ ] Filter chip count badges are readable
- [ ] Question numbers are readable
- [ ] Correct/incorrect indicators are clear
- [ ] Answer options show correct/incorrect states clearly
- [ ] Explanation button is visible

#### Dark Mode Checks
- [ ] Filter chips maintain contrast in dark mode
- [ ] Filter chip count badges are readable (no white-on-white)
- [ ] Question numbers contrast properly with dark background
- [ ] Correct/incorrect indicators remain clear
- [ ] Answer option states are distinguishable in dark mode
- [ ] Explanation button is visible and distinguishable

#### Theme Switching
- [ ] Switch themes while reviewing - UI updates immediately
- [ ] Filter state is preserved during theme switch
- [ ] Scroll position is maintained

---

### 4. Exam Result Screen
**File:** `lib/features/exam/exam_result_screen.dart`

#### Light Mode Checks
- [ ] Score percentage is readable
- [ ] Grade badge is visible
- [ ] Grade badge text is readable
- [ ] Statistics are clear
- [ ] Progress bar is visible
- [ ] Action buttons are visible

#### Dark Mode Checks
- [ ] Score percentage contrasts properly
- [ ] Grade badge is visible in dark mode
- [ ] Grade badge text is readable (no white-on-white)
- [ ] Statistics maintain contrast
- [ ] Progress bar is visible against dark background
- [ ] Action buttons are visible and distinguishable

#### Theme Switching
- [ ] Switch themes on results screen - UI updates immediately
- [ ] All data remains visible after theme switch

---

## Analytics Screen Testing

### 5. Analytics Dashboard
**File:** `lib/features/analytics/analytics_dashboard_screen.dart`

#### Light Mode Checks
- [ ] Overview cards are visible
- [ ] Stat icons are visible and distinct
- [ ] Quick stats are readable
- [ ] Analytics tiles are visible
- [ ] Navigation icons are visible

#### Dark Mode Checks
- [ ] Overview cards maintain contrast
- [ ] Stat icons remain distinct in dark mode
- [ ] Quick stats are readable against dark background
- [ ] Analytics tiles are visible and distinguishable
- [ ] Navigation icons contrast properly

#### Theme Switching
- [ ] Switch themes on dashboard - UI updates immediately
- [ ] All statistics remain visible

---

### 6. Quiz Performance Screen
**File:** `lib/features/analytics/quiz_performance_screen.dart`

#### Light Mode Checks
- [ ] Performance overview stat icons are visible
- [ ] Score trend chart is visible
- [ ] Chart grid lines are visible but subtle
- [ ] Chart line is clear and distinct
- [ ] Chart dots are visible
- [ ] Recent results score badges are readable
- [ ] Score colors (green/orange/red) are distinct

#### Dark Mode Checks
- [ ] Performance overview stat icons maintain contrast
- [ ] Score trend chart is visible in dark mode
- [ ] Chart grid lines don't disappear in dark mode
- [ ] Chart line remains clear and distinct
- [ ] Chart dots are visible against dark background
- [ ] Recent results score badges are readable
- [ ] Score colors maintain distinctness in dark mode

#### Theme Switching
- [ ] Switch themes - chart updates immediately
- [ ] Chart data remains accurate after theme switch

---

### 7. Weak Topics Screen
**File:** `lib/features/analytics/weak_topics_screen.dart`

#### Light Mode Checks
- [ ] Success icon is visible
- [ ] Weak topic items are visible
- [ ] Accuracy colors are distinct
- [ ] Progress bars are visible
- [ ] Bar chart is visible
- [ ] Chart bars have distinct colors
- [ ] Recommendation icon is visible

#### Dark Mode Checks
- [ ] Success icon maintains contrast
- [ ] Weak topic items remain visible
- [ ] Accuracy colors remain distinct in dark mode
- [ ] Progress bars are visible against dark background
- [ ] Bar chart is visible in dark mode
- [ ] Chart bars maintain distinct colors
- [ ] Recommendation icon contrasts properly

#### Theme Switching
- [ ] Switch themes - all charts update immediately
- [ ] Weak topic list remains scrollable

---

### 8. Subject Accuracy Screen
**File:** `lib/features/analytics/subject_accuracy_screen.dart`

#### Light Mode Checks
- [ ] Overall accuracy card is visible
- [ ] Accuracy color indicator is clear
- [ ] Accuracy chart is visible
- [ ] Chart bars have distinct colors
- [ ] Deck list items are visible
- [ ] Deck accuracy badges are readable

#### Dark Mode Checks
- [ ] Overall accuracy card maintains contrast
- [ ] Accuracy color indicator remains clear
- [ ] Accuracy chart is visible in dark mode
- [ ] Chart bars maintain distinct colors
- [ ] Deck list items remain visible
- [ ] Deck accuracy badges are readable

#### Theme Switching
- [ ] Switch themes - charts update immediately
- [ ] Deck list remains scrollable

---

## AI Generate Screen Testing

### 9. AI Generate Home Screen
**File:** `lib/features/ai_generate/ai_generate_home_screen.dart`

#### Light Mode Checks
- [ ] Import option cards are visible
- [ ] Document type icons (PDF, TXT, DOCX) are distinct
- [ ] Icon colors are appropriate for document types
- [ ] Quota display is visible
- [ ] API key setup UI is clear

#### Dark Mode Checks
- [ ] Import option cards maintain contrast
- [ ] Document type icons remain distinct in dark mode
- [ ] Icon colors maintain readability
- [ ] Quota display contrasts properly
- [ ] API key setup UI is readable

#### Theme Switching
- [ ] Switch themes - import cards update immediately
- [ ] API key input field remains usable

---

### 10. Camera OCR Screen
**File:** `lib/features/ai_generate/camera_ocr_screen.dart`

#### Light Mode Checks
- [ ] Camera view is visible
- [ ] Overlay text is readable
- [ ] Corner markers are visible
- [ ] Capture button is visible
- [ ] Loading indicator is visible

#### Dark Mode Checks
- [ ] Camera view is visible
- [ ] Overlay text contrasts properly with camera feed
- [ ] Corner markers are visible against any background
- [ ] Capture button is visible and distinguishable
- [ ] Loading indicator is visible

#### Theme Switching
- [ ] Switch themes - overlay updates immediately
- [ ] Camera functionality remains intact

---

### 11. Document Preview Screens
**Files:** `lib/features/ai_generate/pdf_preview_screen.dart`, `heading_selection_screen.dart`

#### Light Mode Checks
- [ ] PDF viewer is visible
- [ ] Selection controls are visible
- [ ] Page selection checkboxes are clear
- [ ] Heading list is readable
- [ ] Extract button is visible

#### Dark Mode Checks
- [ ] PDF viewer is visible
- [ ] Selection controls maintain contrast
- [ ] Page selection checkboxes remain clear
- [ ] Heading list is readable against dark background
- [ ] Extract button is visible and distinguishable

#### Theme Switching
- [ ] Switch themes - selection UI updates immediately
- [ ] PDF viewer remains functional

---

## Deck & Flashcard Screen Testing

### 12. Deck List Screen
**File:** `lib/features/decks/deck_list_screen.dart`

#### Light Mode Checks
- [ ] Deck cards are visible
- [ ] Deck icons are visible on colored backgrounds
- [ ] Deck names are readable
- [ ] Card counts are readable
- [ ] Bookmark icons are visible
- [ ] FAB is visible

#### Dark Mode Checks
- [ ] Deck cards maintain contrast
- [ ] Deck icons remain visible on colored backgrounds
- [ ] Deck names are readable against dark background
- [ ] Card counts are readable
- [ ] Bookmark icons contrast properly
- [ ] FAB is visible and distinguishable

#### Theme Switching
- [ ] Switch themes - deck list updates immediately
- [ ] Bookmark state is preserved

---

### 13. Deck Details Screen
**File:** `lib/features/decks/deck_details_screen.dart`

#### Light Mode Checks
- [ ] Deck header is visible
- [ ] Deck icon is visible
- [ ] Deck statistics are readable
- [ ] Flashcard list is visible
- [ ] Action buttons are visible

#### Dark Mode Checks
- [ ] Deck header maintains contrast
- [ ] Deck icon remains visible
- [ ] Deck statistics are readable
- [ ] Flashcard list remains visible
- [ ] Action buttons are visible and distinguishable

#### Theme Switching
- [ ] Switch themes - deck details update immediately
- [ ] Flashcard list remains scrollable

---

### 14. Study Home Screen
**File:** `lib/features/study/study_home_screen.dart`

#### Light Mode Checks
- [ ] Statistics cards are visible
- [ ] Stat icons are distinct
- [ ] Stat values are readable
- [ ] Quick action buttons are visible
- [ ] Recent sessions list is visible

#### Dark Mode Checks
- [ ] Statistics cards maintain contrast
- [ ] Stat icons remain distinct in dark mode
- [ ] Stat values are readable against dark background
- [ ] Quick action buttons are visible and distinguishable
- [ ] Recent sessions list remains visible

#### Theme Switching
- [ ] Switch themes - statistics update immediately
- [ ] Action buttons remain functional

---

## Settings Screen Testing

### 15. Settings Screen
**File:** `lib/features/settings/settings_screen.dart`

#### Light Mode Checks
- [ ] Section headers are visible
- [ ] List tiles are visible
- [ ] Icons are visible
- [ ] Navigation chevrons are visible

#### Dark Mode Checks
- [ ] Section headers maintain contrast
- [ ] List tiles remain visible
- [ ] Icons contrast properly
- [ ] Navigation chevrons are visible

#### Theme Switching
- [ ] Switch themes - settings list updates immediately
- [ ] All navigation remains functional

---

### 16. Security Settings Screen
**File:** `lib/features/settings/security_settings_screen.dart`

#### Light Mode Checks
- [ ] Security options are visible
- [ ] Delete icon is visible (red color)
- [ ] Destructive buttons are visible
- [ ] Warning text is readable

#### Dark Mode Checks
- [ ] Security options maintain contrast
- [ ] Delete icon remains visible (appropriate red)
- [ ] Destructive buttons remain visible
- [ ] Warning text is readable

#### Theme Switching
- [ ] Switch themes - security options update immediately
- [ ] Destructive actions remain clearly marked

---

## Overlay & Component Testing

### 17. Notification Banners
**File:** `lib/core/providers/notification_service.dart`

#### Light Mode Checks
- [ ] Success banner is visible with green theme
- [ ] Info banner is visible with blue theme
- [ ] Warning banner is visible with yellow theme
- [ ] Error banner is visible with red theme
- [ ] Banner text is readable
- [ ] Banner icons are visible
- [ ] Undo button is visible (when present)

#### Dark Mode Checks
- [ ] Success banner maintains green theme in dark mode
- [ ] Info banner maintains blue theme in dark mode
- [ ] Warning banner maintains yellow theme in dark mode
- [ ] Error banner maintains red theme in dark mode
- [ ] Banner text is readable against dark background
- [ ] Banner icons remain visible
- [ ] Undo button remains visible

#### Theme Switching
- [ ] Switch themes - existing banners update immediately
- [ ] New banners use correct theme colors

---

### 18. Loading Overlays
**File:** `lib/shared/widgets/app_loading_screen.dart`

#### Light Mode Checks
- [ ] Loading spinner is visible
- [ ] Loading message is readable
- [ ] Logo/icon is visible
- [ ] Overlay background is appropriate

#### Dark Mode Checks
- [ ] Loading spinner is visible in dark mode
- [ ] Loading message is readable against dark background
- [ ] Logo/icon remains visible
- [ ] Overlay background doesn't blend with content

#### Theme Switching
- [ ] Switch themes during loading - overlay updates immediately
- [ ] Loading animation continues smoothly

---

### 19. Custom Button Component
**File:** `lib/shared/widgets/custom_button.dart`

#### Light Mode Checks
- [ ] Elevated buttons are visible
- [ ] Outlined buttons are visible
- [ ] Button text is readable
- [ ] Button icons are visible
- [ ] Loading spinner is visible (when loading)
- [ ] Disabled state is clear

#### Dark Mode Checks
- [ ] Elevated buttons maintain contrast
- [ ] Outlined buttons remain visible
- [ ] Button text is readable in dark mode
- [ ] Button icons contrast properly
- [ ] Loading spinner is visible (no white-on-white)
- [ ] Disabled state remains clear

#### Theme Switching
- [ ] Switch themes - buttons update immediately
- [ ] Button states remain functional

---

## Runtime Theme Switching Test

### Comprehensive Theme Switch Test
1. [ ] Open app in light mode
2. [ ] Navigate to Study Session screen
3. [ ] Start studying a flashcard
4. [ ] Switch device theme to dark mode
5. [ ] Return to app - verify UI updates immediately
6. [ ] Continue studying - verify all elements are visible
7. [ ] Switch back to light mode
8. [ ] Verify UI updates immediately
9. [ ] Navigate to Exam screen
10. [ ] Start an exam
11. [ ] Switch theme during exam
12. [ ] Verify question and answers remain visible
13. [ ] Complete exam and go to results
14. [ ] Switch theme on results screen
15. [ ] Verify all statistics remain visible
16. [ ] Navigate to Analytics
17. [ ] View various charts
18. [ ] Switch theme multiple times
19. [ ] Verify charts update and remain readable
20. [ ] Navigate to Settings
21. [ ] Change app theme setting
22. [ ] Verify app theme overrides system theme
23. [ ] Set app theme back to "System"
24. [ ] Change device theme
25. [ ] Verify app follows system theme

---

## Accessibility Testing

### Contrast Verification
- [ ] Use contrast checker tool on all primary screens
- [ ] Verify text contrast meets WCAG AA (4.5:1 for normal text)
- [ ] Verify large text contrast meets WCAG AA (3:1 for 18pt+)
- [ ] Verify interactive elements have sufficient contrast
- [ ] Verify chart elements are distinguishable by color blind users

### Screen Reader Testing
- [ ] Enable TalkBack (Android) or VoiceOver (iOS)
- [ ] Navigate through Study screen
- [ ] Verify all elements are announced properly
- [ ] Verify theme changes don't affect screen reader
- [ ] Verify chart data is accessible

### Keyboard Navigation
- [ ] Connect external keyboard
- [ ] Navigate through app using keyboard
- [ ] Verify focus indicators are visible in both themes
- [ ] Verify focus indicators contrast properly

---

## Device-Specific Testing

### Android Testing
- [ ] Test on Android 12+ (Material 3 support)
- [ ] Test on Android 10-11 (Material 2 fallback)
- [ ] Test with different OEM themes (Samsung, Pixel, etc.)
- [ ] Test with different display modes (High contrast, Color inversion)

### iOS Testing
- [ ] Test on iOS 15+
- [ ] Test with different iOS appearances
- [ ] Test with Increase Contrast setting
- [ ] Test with Differentiate Without Color setting

---

## Performance Testing

### Theme Switch Performance
- [ ] Measure time to switch themes on main screens
- [ ] Verify no jank during theme transition
- [ ] Verify smooth animations during theme switch
- [ ] Test theme switching on low-end devices

### Memory Impact
- [ ] Monitor memory usage during theme switches
- [ ] Verify no memory leaks from theme changes
- [ ] Test extended use with frequent theme switching

---

## Regression Testing

### Functional Testing Post-Theme Fixes
- [ ] Study session functionality works correctly
- [ ] Exam creation and taking works correctly
- [ ] Analytics data displays correctly
- [ ] AI question generation works correctly
- [ ] Deck management works correctly
- [ ] Settings and preferences work correctly
- [ ] Backup and restore works correctly
- [ ] All navigation works correctly

---

## Sign-Off Criteria

### Before Sign-Off
- [ ] All critical issues from audit report are resolved
- [ ] All major issues from audit report are resolved
- [ ] All minor issues from audit report are resolved
- [ ] Runtime theme switching works on all screens
- [ ] All screens pass manual testing in both themes
- [ ] Accessibility contrast meets WCAG AA standards
- [ ] No regressions in core functionality
- [ ] Performance is acceptable during theme switches
- [ ] Widget tests pass for theme-aware components
- [ ] Golden tests pass for critical screens

### Final Approval
- [ ] QA Lead approval
- [ ] UI/UX Designer approval
- [ ] Product Owner approval
- [ ] Accessibility audit passed

---

## Issue Tracking

### Issues Found During Testing
Record any new issues discovered during testing:

| Issue ID | Screen | Description | Severity | Status |
|----------|--------|-------------|----------|---------|
| | | | | |

### Test Results Summary
- **Total Screens Tested:** ___/___
- **Screens Passed:** ___/___
- **Screens Failed:** ___/___
- **Critical Issues Found:** ___
- **Major Issues Found:** ___
- **Minor Issues Found:** ___

### Tester Notes
Add any additional observations or recommendations:

---

## Appendix: Quick Reference

### Theme-Aware Color Usage
**DO:**
```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onSurface
Theme.of(context).colorScheme.surface
AppTheme.bambooGreen600
AppTheme.red600
```

**DON'T:**
```dart
Colors.white
Colors.black
Colors.red
Colors.green
Colors.blue
Color(0xFF123456)
```

### Common Theme Issues
1. **White text on white background** - Use `Theme.of(context).colorScheme.onPrimary`
2. **Black text on dark background** - Use `Theme.of(context).colorScheme.onSurface`
3. **Hard-coded shadows** - Use `AppTheme.shadow` or `AppTheme.shadowDark`
4. **Hard-coded overlays** - Use `Theme.of(context).colorScheme.scrim`
5. **Icon visibility** - Use theme-aware colors or contrast calculation

### Testing Commands
```bash
# Run widget tests
flutter test test/widgets/theme_aware_widgets_test.dart

# Run golden tests
flutter test --update-goldens test/goldens/

# Run integration tests
flutter test integration_test/theme_switching_test.dart
```

---

**Document Maintenance:** This checklist should be updated after each theme-related release to reflect new screens or components.

**Questions or Issues:** Contact the UI/UX team or Flutter development lead for clarification on theme requirements.
