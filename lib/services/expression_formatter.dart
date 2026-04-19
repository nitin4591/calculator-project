class ExpressionFormatter {
  const ExpressionFormatter._();

  static String toDisplay(String expression) {
    if (expression.trim().isEmpty) {
      return '0';
    }

    return expression
        .replaceAll('*', ' * ')
        .replaceAll('/', ' / ');
  }

  static String formatResult(double value) {
    if (!value.isFinite) {
      return 'Error';
    }

    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    final absolute = value.abs();
    if (absolute >= 10000000000 || (absolute > 0 && absolute < 0.000001)) {
      return value.toStringAsExponential(6);
    }

    return _trimTrailingZeros(value.toStringAsPrecision(12));
  }

  static String _trimTrailingZeros(String input) {
    if (input.contains('e') || input.contains('E')) {
      return input;
    }

    return input.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
