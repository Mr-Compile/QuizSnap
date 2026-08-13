import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quiz_snap/core/providers/notification_service.dart';
import 'package:quiz_snap/core/theme/app_theme.dart';
import 'package:quiz_snap/features/study/rate_card_bottom_sheet.dart';
import 'package:quiz_snap/shared/widgets/app_loading_screen.dart';
import 'package:quiz_snap/shared/widgets/app_toast_overlay.dart';
import 'package:quiz_snap/shared/widgets/top_banner_overlay.dart';

// Run with the flag below to generate golden baselines:
//   flutter test --update-goldens test/theme/golden_test.dart
void main() {
  group('Golden critical screens - generate baselines with --update-goldens', () {
    testWidgets(
      'LoadingOverlay light',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoadingOverlay(message: 'Loading'),
          ),
        );
        await expectLater(
          find.byType(LoadingOverlay),
          matchesGoldenFile('goldens/loading_overlay_light.png'),
        );
      },
      skip: true,
    );

    testWidgets(
      'LoadingOverlay dark',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoadingOverlay(message: 'Loading'),
          ),
        );
        await expectLater(
          find.byType(LoadingOverlay),
          matchesGoldenFile('goldens/loading_overlay_dark.png'),
        );
      },
      skip: true,
    );

    testWidgets(
      'RateCardBottomSheet light',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: RateCardBottomSheet(onRated: (_) {})),
          ),
        );
        await expectLater(
          find.byType(RateCardBottomSheet),
          matchesGoldenFile('goldens/rate_card_bottom_sheet_light.png'),
        );
      },
      skip: true,
    );

    testWidgets(
      'TopBannerOverlay light',
      (WidgetTester tester) async {
        final service = NotificationService()..showSuccess('Saved');
        await tester.pumpWidget(
          ChangeNotifierProvider<NotificationService>.value(
            value: service,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: TopBannerOverlay(child: Container()),
            ),
          ),
        );
        await expectLater(
          find.byType(TopBannerOverlay),
          matchesGoldenFile('goldens/top_banner_overlay_light.png'),
        );
      },
      skip: true,
    );

    testWidgets(
      'AppToastOverlay light',
      (WidgetTester tester) async {
        final service = NotificationService()..showSuccessToast('Copied');
        await tester.pumpWidget(
          ChangeNotifierProvider<NotificationService>.value(
            value: service,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: AppToastOverlay(child: Container()),
            ),
          ),
        );
        await expectLater(
          find.byType(AppToastOverlay),
          matchesGoldenFile('goldens/app_toast_overlay_light.png'),
        );
      },
      skip: true,
    );
  });
}
