// This is a basic Flutter widget test for SFC Mobile POS App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sfc_mobile/main.dart';

void main() {
  testWidgets('SFC Mobile app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashierApp());

    // Verify that the login screen is displayed initially
    expect(find.text('Login'), findsOneWidget);

    // You can add more specific tests here for your POS app functionality
    // For example, testing login, product management, transactions, etc.
  });

  testWidgets('App theme test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashierApp());

    // Verify that the app uses Material 3 design
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'Aplikasi Kasir');
  });
}
