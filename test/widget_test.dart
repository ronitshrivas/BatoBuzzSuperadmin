import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:batobuzzadmin/main.dart';
import 'package:batobuzzadmin/core/auth/auth_provider.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(BatoBuzzAdminApp(auth: AuthProvider()));
    await tester.pump();

    // App renders something (no crash on boot).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
