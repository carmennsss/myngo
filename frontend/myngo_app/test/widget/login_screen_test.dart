import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myngo_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen has email and password fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Verify that our fields are present.
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Iniciar Sesión'), findsWidgets);
  });
}
