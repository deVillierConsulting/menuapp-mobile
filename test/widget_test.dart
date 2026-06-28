import 'package:flutter_test/flutter_test.dart';
import 'package:menuapp_mobile/app.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('MenuApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MenuApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
