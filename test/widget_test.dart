import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/main.dart';

void main() {
  testWidgets('PantryPal app shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PantryPalApp());

    expect(find.text('PantryPal AI'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
  });
}
