import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_pokoknya/main.dart';
import 'package:aplikasi_pokoknya/providers/auth_provider.dart';
import 'package:aplikasi_pokoknya/services/auth_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Override authProvider so the app doesn't try to reach Firebase.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
        child: const App(),
      ),
    );

    // Pump past the opening animation (2.5 s delay + 1 s curtain).
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // After the opening animation, the login screen should be visible.
    expect(find.text('MASUK'), findsOneWidget);
  });

  testWidgets('Firebase startup errors are shown instead of a blank screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: App(
          firebaseInitializationError: UnsupportedError('web not set up'),
        ),
      ),
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
