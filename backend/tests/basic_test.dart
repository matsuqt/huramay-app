import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Huramay Essential Frontend Tests', () {
    test('Math still works (Sanity Check)', () {
      expect(2 + 2, 4);
    });

    test('String formatting is correct', () {
      String appName = "Huramay";
      expect(appName.toUpperCase(), "HURAMAY");
    });
  });
}