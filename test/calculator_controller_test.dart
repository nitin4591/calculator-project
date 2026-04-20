import 'package:flutter_test/flutter_test.dart';
import 'package:modern_calculator/services/calculator_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CalculatorController persistence', () {
    test('loads saved expression and preview result', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'expression': '12+3',
        'previewResult': '15',
      });

      final controller = CalculatorController();
      await controller.initialize();

      expect(controller.expression, '12+3');
      expect(controller.previewResult, '15');
    });

    test('saves session after input', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final controller = CalculatorController();
      await controller.initialize();
      controller.appendNumber('7');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('expression'), '7');
      expect(prefs.getString('previewResult'), '7');
    });
  });
}
