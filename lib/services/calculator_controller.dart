import 'dart:async';

import 'package:flutter/material.dart';
import 'package:modern_calculator/models/history_entry.dart';
import 'package:modern_calculator/services/calculator_engine.dart';
import 'package:modern_calculator/services/expression_formatter.dart';
import 'package:modern_calculator/services/storage_service.dart';

class CalculatorController extends ChangeNotifier {
  final CalculatorEngine _engine = CalculatorEngine();
  final StorageService _storageService = StorageService();

  String expression = '';
  String previewResult = '0';
  ThemeMode themeMode = ThemeMode.dark;
  bool scientificMode = false;
  bool useDegrees = true;
  List<HistoryEntry> history = <HistoryEntry>[];

  bool _replaceExpressionOnNextInput = false;

  bool get isDarkMode => themeMode == ThemeMode.dark;
  String get displayExpression => ExpressionFormatter.toDisplay(expression);

  Future<void> initialize() async {
    final preferences = await _storageService.loadPreferences();
    themeMode = preferences.themeMode;
    scientificMode = preferences.scientificMode;
    useDegrees = preferences.useDegrees;
    history = preferences.history;
    expression = preferences.expression;
    previewResult = preferences.previewResult;
    _refreshPreview(notify: false, persist: false);
    notifyListeners();
  }

  void setScientificMode(bool value) {
    scientificMode = value;
    _storageService.saveScientificMode(value);
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _storageService.saveThemeMode(themeMode);
    notifyListeners();
  }

  void toggleAngleUnit() {
    useDegrees = !useDegrees;
    _storageService.saveAngleMode(useDegrees);
    _refreshPreview();
  }

  void clear() {
    expression = '';
    previewResult = '0';
    _replaceExpressionOnNextInput = false;
    _persistSession();
    notifyListeners();
  }

  void deleteLast() {
    if (_replaceExpressionOnNextInput) {
      clear();
      return;
    }

    if (expression.isEmpty) {
      return;
    }

    expression = expression.substring(0, expression.length - 1);
    _refreshPreview();
  }

  void appendNumber(String value) {
    _prepareForFreshInput();

    if (_needsImplicitMultiplicationBeforeNumber()) {
      expression += '*';
    }

    expression += value;
    _refreshPreview();
  }

  void appendDecimal() {
    _prepareForFreshInput();

    if (expression.isEmpty || _endsWithOperatorOrOpenParen()) {
      expression += '0.';
      _refreshPreview();
      return;
    }

    if (_endsWithClosedValue()) {
      expression += '*0.';
      _refreshPreview();
      return;
    }

    final trailingNumber = _extractTrailingNumber();
    if (trailingNumber.contains('.')) {
      return;
    }

    expression += '.';
    _refreshPreview();
  }

  void appendOperator(String operator) {
    if (expression.isEmpty) {
      if (operator == '-') {
        expression = '-';
        _refreshPreview();
      }
      return;
    }

    if (_replaceExpressionOnNextInput && previewResult != 'Error') {
      expression = previewResult;
      _replaceExpressionOnNextInput = false;
    }

    _replaceExpressionOnNextInput = false;

    if (_endsWithUnaryMinus()) {
      expression = expression.substring(0, expression.length - 1);
    }

    if (_endsWithOperator()) {
      final lastOperator = expression[expression.length - 1];
      if (operator == '-' && '*/%^'.contains(lastOperator)) {
        expression += operator;
      } else {
        expression = expression.substring(0, expression.length - 1) + operator;
      }
      _refreshPreview();
      return;
    }

    if (_endsWithOpenParen()) {
      if (operator == '-') {
        expression += operator;
        _refreshPreview();
      }
      return;
    }

    expression += operator;
    _refreshPreview();
  }

  void appendFunction(String name) {
    _prepareForFreshInput();

    if (_needsImplicitMultiplicationBeforeAtomic()) {
      expression += '*';
    }

    expression += '$name(';
    _refreshPreview();
  }

  void appendConstant(String name) {
    _prepareForFreshInput();

    if (_needsImplicitMultiplicationBeforeAtomic()) {
      expression += '*';
    }

    expression += name;
    _refreshPreview();
  }

  void appendOpenParenthesis() {
    _prepareForFreshInput();

    if (_needsImplicitMultiplicationBeforeAtomic()) {
      expression += '*';
    }

    expression += '(';
    _refreshPreview();
  }

  void appendCloseParenthesis() {
    if (_parenthesisBalance(expression) <= 0 || _endsWithOperatorOrOpenParen()) {
      return;
    }

    expression += ')';
    _refreshPreview();
  }

  void appendSquare() {
    if (!_canAppendPostfix()) {
      return;
    }

    _replaceExpressionOnNextInput = false;
    expression += '^2';
    _refreshPreview();
  }

  void appendFactorial() {
    if (!_canAppendPostfix()) {
      return;
    }

    _replaceExpressionOnNextInput = false;
    expression += '!';
    _refreshPreview();
  }

  Future<void> evaluate() async {
    if (expression.isEmpty) {
      return;
    }

    final normalizedExpression = _normalizedExpression(expression);

    try {
      final value =
          _engine.evaluate(normalizedExpression, useDegrees: useDegrees);
      final result = ExpressionFormatter.formatResult(value);

      final entry = HistoryEntry(
        expression: normalizedExpression,
        result: result,
        createdAt: DateTime.now(),
      );

      if (history.isEmpty ||
          history.first.expression != entry.expression ||
          history.first.result != entry.result) {
        history = <HistoryEntry>[entry, ...history].take(25).toList();
        await _storageService.saveHistory(history);
      }

      previewResult = result;
      _replaceExpressionOnNextInput = true;
      _persistSession();
      notifyListeners();
    } catch (_) {
      previewResult = 'Error';
      _replaceExpressionOnNextInput = true;
      _persistSession();
      notifyListeners();
    }
  }

  void useHistoryEntry(HistoryEntry entry) {
    expression = entry.expression;
    previewResult = entry.result;
    _replaceExpressionOnNextInput = false;
    _persistSession();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = <HistoryEntry>[];
    await _storageService.saveHistory(history);
    notifyListeners();
  }

  void _prepareForFreshInput() {
    if (_replaceExpressionOnNextInput) {
      expression = '';
      previewResult = '0';
      _replaceExpressionOnNextInput = false;
    }
  }

  void _refreshPreview({bool notify = true, bool persist = true}) {
    if (expression.trim().isEmpty) {
      previewResult = '0';
      if (persist) {
        _persistSession();
      }
      if (notify) {
        notifyListeners();
      }
      return;
    }

    try {
      final value =
          _engine.evaluate(_normalizedExpression(expression), useDegrees: useDegrees);
      previewResult = ExpressionFormatter.formatResult(value);
    } catch (_) {
      previewResult = '...';
    }

    if (persist) {
      _persistSession();
    }

    if (notify) {
      notifyListeners();
    }
  }

  void _persistSession() {
    _storageService
        .saveSession(
          expression: expression,
          previewResult: previewResult,
        )
        .ignore();
  }

  String _normalizedExpression(String input) {
    final balance = _parenthesisBalance(input);
    if (balance <= 0) {
      return input;
    }

    return '$input${List.filled(balance, ')').join()}';
  }

  int _parenthesisBalance(String input) {
    return '('.allMatches(input).length - ')'.allMatches(input).length;
  }

  String _extractTrailingNumber() {
    final match =
        RegExp(r'([0-9]+(?:\.[0-9]*)?)$').firstMatch(expression);
    return match?.group(0) ?? '';
  }

  bool _needsImplicitMultiplicationBeforeNumber() => _endsWithClosedValue();

  bool _needsImplicitMultiplicationBeforeAtomic() =>
      _endsWithClosedValue() || _endsWithNumberLike();

  bool _canAppendPostfix() => _endsWithClosedValue() || _endsWithNumberLike();

  bool _endsWithNumberLike() =>
      expression.isNotEmpty && RegExp(r'[0-9.]$').hasMatch(expression);

  bool _endsWithClosedValue() =>
      expression.endsWith(')') ||
      expression.endsWith('!') ||
      expression.endsWith('pi') ||
      expression.endsWith('e');

  bool _endsWithOpenParen() => expression.endsWith('(');

  bool _endsWithOperator() =>
      expression.isNotEmpty && _isOperator(expression[expression.length - 1]);

  bool _endsWithOperatorOrOpenParen() =>
      expression.isEmpty || _endsWithOperator() || _endsWithOpenParen();

  bool _endsWithUnaryMinus() {
    if (!expression.endsWith('-') || expression.length == 1) {
      return false;
    }

    final previous = expression[expression.length - 2];
    return _isOperator(previous) || previous == '(';
  }

  bool _isOperator(String value) => '+-*/%^'.contains(value);
}
