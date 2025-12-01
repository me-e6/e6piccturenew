import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e6piccturenew/features/auth/login/login_screen.dart';

void main() {
  testWidgets("Login screen renders correctly", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Check text fields exist
    expect(find.byType(TextField), findsNWidgets(2));

    // Check for Login button
    expect(find.text("Login"), findsOneWidget);
  });

  testWidgets("Password visibility toggle works", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    final toggleButton = find.byIcon(Icons.visibility_off);
    expect(toggleButton, findsOneWidget);

    // Tap toggle
    await tester.tap(toggleButton);
    await tester.pump();

    // Should now show visible icon
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
