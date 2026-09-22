// Smoke test — ยืนยันว่าแอปตั้งค่า Provider ครบและขึ้นหน้าล็อกอินได้โดยไม่ crash
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipe_app/main.dart';

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RecipeApp());
    await tester.pumpAndSettle();

    expect(find.text('สูตรอาหาร'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    expect(find.text('ดูสูตรอาหารโดยไม่เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('Guest can continue into the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RecipeApp());
    await tester.pumpAndSettle();

    final guestButton = find.text('ดูสูตรอาหารโดยไม่เข้าสู่ระบบ');
    await tester.ensureVisible(guestButton);
    await tester.pumpAndSettle();
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('กินอะไรดี'), findsOneWidget);
  });
}
