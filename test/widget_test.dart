import 'package:flutter_test/flutter_test.dart';
import 'package:modern_calculator/main.dart';
import 'package:modern_calculator/services/calculator_controller.dart';
import 'package:modern_calculator/widgets/calculator_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('tapping a number button updates controller state',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = CalculatorController();
    await controller.initialize();

    await tester.pumpWidget(CalculatorRoot(controller: controller));

    await tester.tap(find.widgetWithText(CalculatorButton, '1'));
    await tester.pump();

    expect(controller.expression, '1');
    expect(controller.previewResult, '1');
  });
}
