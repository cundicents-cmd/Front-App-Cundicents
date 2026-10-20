// This is a basic Flutter widget test for Cundicents.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cundicents/main.dart';

void main() {
  testWidgets('CundicentsApp builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CundicentsApp());

    // Verify the app builds and shows a loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}