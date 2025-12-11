import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteplus/main.dart';

void main() {
  testWidgets('NotePlus app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NotePlusApp());

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
