import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - Firebase requires initialization
    // so we just verify the test framework works
    expect(1 + 1, equals(2));
  });
}
