// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nyumba_mkononi/screens/add_property_screen.dart';

void main() {
  testWidgets('add property wizard shows type selection and room price step', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddPropertyScreen()));

    expect(find.text('Chagua aina ya mali'), findsOneWidget);
    expect(find.text('Nyumba'), findsWidgets);
    expect(find.text('Chumba'), findsWidgets);
    expect(find.text('Kiwanja'), findsWidgets);

    await tester.tap(find.text('Chumba'));
    await tester.pumpAndSettle();

    expect(find.text('Bei ya chumba kwa mwezi'), findsOneWidget);
    expect(find.text('Hifadhi na endelea'), findsOneWidget);
  });
}
