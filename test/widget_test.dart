import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worl_of_rice/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const JoyWorldOfRiceApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
