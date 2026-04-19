import 'package:flutter_test/flutter_test.dart';
import 'package:modern_calculator/services/calculator_engine.dart';

void main() {
  final engine = CalculatorEngine();

  group('CalculatorEngine', () {
    test('evaluates operator precedence', () {
      final result = engine.evaluate('2+3*4', useDegrees: true);
      expect(result, 14);
    });

    test('evaluates trigonometric functions in degree mode', () {
      final result = engine.evaluate('sin(30)+cos(60)', useDegrees: true);
      expect(result, closeTo(1.0, 0.000001));
    });

    test('evaluates powers and parentheses', () {
      final result = engine.evaluate('(2+3)^2', useDegrees: true);
      expect(result, 25);
    });

    test('evaluates factorial', () {
      final result = engine.evaluate('5!', useDegrees: true);
      expect(result, 120);
    });

    test('supports negative exponents', () {
      final result = engine.evaluate('2^-3', useDegrees: true);
      expect(result, closeTo(0.125, 0.000001));
    });
  });
}
