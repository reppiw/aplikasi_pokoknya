import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_pokoknya/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Basic smoke test — just ensure the app builds without throwing.
    expect(find.byType(App), findsOneWidget);
  });
}
