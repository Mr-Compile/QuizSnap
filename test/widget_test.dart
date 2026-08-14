// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quiz_snap/main.dart';
import 'package:quiz_snap/core/providers/database_provider.dart';
import 'package:quiz_snap/core/providers/security_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize database provider
    final dbProvider = DatabaseProvider();
    await dbProvider.initializeDatabase();
    
    await tester.pumpWidget(QuizSnapApp(
      prefs: prefs,
      dbProvider: dbProvider,
      securityProvider: SecurityProvider(),
    ));

    // Verify that our app builds.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
