// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpmobilapp/main.dart';
import 'package:erpmobilapp/screens/login_screen.dart';
import 'package:erpmobilapp/services/theme_service.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Setup SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService(prefs)),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that login screen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Founder ERP'), findsOneWidget);
  });
}
