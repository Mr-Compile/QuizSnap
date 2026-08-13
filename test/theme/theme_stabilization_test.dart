import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_snap/core/providers/notification_service.dart';
import 'package:quiz_snap/core/theme/app_theme.dart';
import 'package:quiz_snap/features/study/rate_card_bottom_sheet.dart';
import 'package:quiz_snap/shared/widgets/app_loading_screen.dart';
import 'package:quiz_snap/shared/widgets/app_toast_overlay.dart';
import 'package:quiz_snap/shared/widgets/custom_button.dart';
import 'package:quiz_snap/shared/widgets/top_banner_overlay.dart';

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

  group('TopBannerOverlay', () {
    testWidgets('success banner uses primaryContainer', (WidgetTester tester) async {
      final service = NotificationService()..showSuccess('Saved successfully');

      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationService>.value(
          value: service,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: TopBannerOverlay(
              child: Container(),
            ),
          ),
        ),
      );

      final banner = find.ancestor(
        of: find.text('Saved successfully'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(banner);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, AppTheme.lightTheme.colorScheme.primaryContainer);

      // Allow the auto-dismiss timer to fire so the test is clean.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('error banner uses errorContainer', (WidgetTester tester) async {
      final service = NotificationService()..showErrorTop('Save failed');

      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationService>.value(
          value: service,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: TopBannerOverlay(
              child: Container(),
            ),
          ),
        ),
      );

      final banner = find.ancestor(
        of: find.text('Save failed'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(banner);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, AppTheme.lightTheme.colorScheme.errorContainer);

      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('AppToastOverlay', () {
    testWidgets('success toast uses primaryContainer', (WidgetTester tester) async {
      final service = NotificationService()..showSuccessToast('Copied');

      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationService>.value(
          value: service,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AppToastOverlay(
              child: Container(),
            ),
          ),
        ),
      );

      final toast = find.ancestor(
        of: find.text('Copied'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(toast);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, AppTheme.lightTheme.colorScheme.primaryContainer);

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('error toast uses errorContainer', (WidgetTester tester) async {
      final service = NotificationService()..showToast(
        'Failed',
        type: InlineMessageType.error,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationService>.value(
          value: service,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AppToastOverlay(
              child: Container(),
            ),
          ),
        ),
      );

      final toast = find.ancestor(
        of: find.text('Failed'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(toast);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, AppTheme.lightTheme.colorScheme.errorContainer);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
