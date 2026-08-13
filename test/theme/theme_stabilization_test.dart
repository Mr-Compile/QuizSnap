import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_snap/core/theme/app_theme.dart';
import 'package:quiz_snap/features/study/rate_card_bottom_sheet.dart';
import 'package:quiz_snap/shared/widgets/app_loading_screen.dart';
import 'package:quiz_snap/shared/widgets/custom_button.dart';

void main() {
  group('CustomButton loading spinner', () {
    testWidgets('spinner uses onPrimary in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CustomButton(text: 'Save', onPressed: null, isLoading: true),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final color = (indicator.valueColor! as AlwaysStoppedAnimation<Color>).value;

      final colorScheme = AppTheme.lightTheme.colorScheme;
      expect(color, colorScheme.onPrimary);
    });

    testWidgets('spinner uses onPrimary in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CustomButton(text: 'Save', onPressed: null, isLoading: true),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final color = (indicator.valueColor! as AlwaysStoppedAnimation<Color>).value;

      final colorScheme = AppTheme.darkTheme.colorScheme;
      expect(color, colorScheme.onPrimary);
    });

    testWidgets('outlined spinner uses primary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CustomButton(
              text: 'Save',
              onPressed: null,
              isLoading: true,
              isOutlined: true,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final color = (indicator.valueColor! as AlwaysStoppedAnimation<Color>).value;

      expect(color, AppTheme.lightTheme.colorScheme.primary);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('barrier is 45% black in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoadingOverlay(message: 'Please wait'),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color!.a, closeTo(0.45, 0.01));
    });

    testWidgets('barrier is 65% black in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoadingOverlay(message: 'Please wait'),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color!.a, closeTo(0.65, 0.01));
    });

    testWidgets('card uses surface and text uses onSurface', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoadingOverlay(message: 'Please wait'),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final text = tester.widget<Text>(find.text('Please wait'));
      final colorScheme = AppTheme.lightTheme.colorScheme;

      expect(card.color, colorScheme.surface);
      expect(text.style?.color, colorScheme.onSurface);
    });
  });

  group('RateCardBottomSheet', () {
    testWidgets('uses semantic container colors in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RateCardBottomSheet(onRated: (_) {}),
          ),
        ),
      );

      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
      final colorScheme = AppTheme.lightTheme.colorScheme;

      expect(buttons.length, 4);

      // Again -> errorContainer/onErrorContainer
      final again = buttons[0];
      final againBg = again.style?.backgroundColor?.resolve({});
      final againFg = again.style?.foregroundColor?.resolve({});
      expect(againBg, colorScheme.errorContainer);
      expect(againFg, colorScheme.onErrorContainer);

      // Good -> primaryContainer/onPrimaryContainer
      final good = buttons[2];
      final goodBg = good.style?.backgroundColor?.resolve({});
      final goodFg = good.style?.foregroundColor?.resolve({});
      expect(goodBg, colorScheme.primaryContainer);
      expect(goodFg, colorScheme.onPrimaryContainer);
    });
  });
}
