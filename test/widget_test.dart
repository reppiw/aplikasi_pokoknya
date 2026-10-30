import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_pokoknya/main.dart';
import 'package:aplikasi_pokoknya/services/auth_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Basic smoke test — just ensure the app builds without throwing.
    expect(find.byType(App), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Firebase startup errors are shown instead of a blank screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(firebaseInitializationError: UnsupportedError('web not set up')),
    );

    expect(
      find.text('Firebase belum dikonfigurasi untuk platform ini.'),
      findsOneWidget,
    );
    expect(find.textContaining('web not set up'), findsOneWidget);
  });

  test('registration rejects users under 16', () {
    expect(
      () => AuthService.instance.register(
        name: 'Test User',
        username: 'underage_test_user',
        password: 'password123',
        age: 15,
      ),
      throwsA(isA<AuthException>()),
    );
  });
}
