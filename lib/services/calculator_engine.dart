import 'dart:math';

class CalculatorEngine {
  double evaluate(String expression, {required bool useDegrees}) {
    final lexer = _Lexer(expression);
    final tokens = lexer.tokenize();

    if (tokens.isEmpty) {
      throw const FormatException('Expression is empty.');
    }

    final parser = _Parser(tokens, useDegrees: useDegrees);
    final result = parser.parse();

    if (!result.isFinite) {
      throw const FormatException('Result is not finite.');
    }

    return result;
  }
}

enum _TokenType {
  number,
  identifier,
  operator,
  leftParen,
  rightParen,
  eof,
}

class _Token {
  const _Token(this.type, this.lexeme);

  final _TokenType type;
  final String lexeme;
}

class _Lexer {
  _Lexer(this._input);

  final String _input;
  int _index = 0;

  List<_Token> tokenize() {
    final tokens = <_Token>[];

    while (!_isAtEnd) {
      final current = _peek();

      if (_isWhitespace(current)) {
        _advance();
        continue;
      }

      if (_isDigit(current) || current == '.') {
        tokens.add(_Token(_TokenType.number, _readNumber()));
        continue;
      }

      if (_isLetter(current) || current == 'π') {
        tokens.add(_Token(_TokenType.identifier, _readIdentifier()));
        continue;
      }

      switch (current) {
        case '+':
        case '-':
        case '*':
        case '/':
        case '%':
        case '^':
        case '!':
        case '×':
        case '÷':
          tokens.add(_Token(_TokenType.operator, _normalizeOperator(current)));
          _advance();
          break;
        case '(':
          tokens.add(const _Token(_TokenType.leftParen, '('));
          _advance();
          break;
        case ')':
          tokens.add(const _Token(_TokenType.rightParen, ')'));
          _advance();
          break;
        default:
          throw FormatException('Unexpected character: $current');
      }
    }

    tokens.add(const _Token(_TokenType.eof, ''));
    return tokens;
  }

  String _readNumber() {
    final buffer = StringBuffer();
    var sawDot = false;

    while (!_isAtEnd) {
      final char = _peek();

      if (_isDigit(char)) {
        buffer.write(char);
        _advance();
        continue;
      }

      if (char == '.' && !sawDot) {
        sawDot = true;
        buffer.write(char);
        _advance();
        continue;
      }

      break;
    }

    if (!_isAtEnd &&
        (_peek() == 'e' || _peek() == 'E') &&
        _hasValidExponentAhead()) {
      buffer.write(_peek());
      _advance();

      if (!_isAtEnd && (_peek() == '+' || _peek() == '-')) {
        buffer.write(_peek());
        _advance();
      }

      while (!_isAtEnd && _isDigit(_peek())) {
        buffer.write(_peek());
        _advance();
      }
    }

    final value = buffer.toString();
    if (value == '.' || value.isEmpty) {
      throw const FormatException('Invalid number.');
    }

    return value;
  }

  String _readIdentifier() {
    final buffer = StringBuffer();

    if (_peek() == 'π') {
      _advance();
      return 'pi';
    }

    while (!_isAtEnd && _isLetter(_peek())) {
      buffer.write(_peek().toLowerCase());
      _advance();
    }

    return buffer.toString();
  }

  bool _hasValidExponentAhead() {
    var lookahead = _index + 1;
    if (lookahead >= _input.length) {
      return false;
    }

    final sign = _input[lookahead];
    if (sign == '+' || sign == '-') {
      lookahead++;
    }

    return lookahead < _input.length && _isDigit(_input[lookahead]);
  }

  String _normalizeOperator(String input) {
    if (input == '×') {
      return '*';
    }
    if (input == '÷') {
      return '/';
    }
    return input;
  }

  bool get _isAtEnd => _index >= _input.length;

  String _peek() => _input[_index];

  void _advance() {
    _index++;
  }

  bool _isDigit(String value) => value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;

  bool _isLetter(String value) {
    final code = value.toLowerCase().codeUnitAt(0);
    return code >= 97 && code <= 122;
  }

  bool _isWhitespace(String value) => value.trim().isEmpty;
}

class _Parser {
  _Parser(this._tokens, {required this.useDegrees});

  final List<_Token> _tokens;
  final bool useDegrees;
  int _current = 0;

  double parse() {
    final value = _parseExpression();
    _expect(_TokenType.eof, 'Unexpected token at the end of expression.');
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();

    while (true) {
      if (_matchOperator('+')) {
        value += _parseTerm();
        continue;
      }

      if (_matchOperator('-')) {
        value -= _parseTerm();
        continue;
      }

      break;
    }

    return value;
  }

  double _parseTerm() {
    var value = _parseUnary();

    while (true) {
      if (_matchOperator('*')) {
        value *= _parseUnary();
        continue;
      }

      if (_matchOperator('/')) {
        final divisor = _parseUnary();
        if (divisor == 0) {
          throw const FormatException('Cannot divide by zero.');
        }
        value /= divisor;
        continue;
      }

      if (_matchOperator('%')) {
        final modulus = _parseUnary();
        if (modulus == 0) {
          throw const FormatException('Cannot modulo by zero.');
        }
        value %= modulus;
        continue;
      }

      break;
    }

    return value;
  }

  double _parseUnary() {
    if (_matchOperator('+')) {
      return _parseUnary();
    }

    if (_matchOperator('-')) {
      return -_parseUnary();
    }

    return _parsePower();
  }

  double _parsePower() {
    var value = _parsePostfix();

    if (_matchOperator('^')) {
      final exponent = _parseUnary();
      value = pow(value, exponent).toDouble();
    }

    return value;
  }

  double _parsePostfix() {
    var value = _parsePrimary();

    while (_matchOperator('!')) {
      value = _factorial(value);
    }

    return value;
  }

  double _parsePrimary() {
    if (_match(_TokenType.number)) {
      return double.parse(_previous.lexeme);
    }

    if (_match(_TokenType.identifier)) {
      final identifier = _previous.lexeme;

      switch (identifier) {
        case 'pi':
          return pi;
        case 'e':
          return e;
        default:
          _expect(_TokenType.leftParen, 'Expected "(" after $identifier.');
          final value = _parseExpression();
          _expect(_TokenType.rightParen, 'Expected ")" after function argument.');
          return _applyFunction(identifier, value);
      }
    }

    if (_match(_TokenType.leftParen)) {
      final value = _parseExpression();
      _expect(_TokenType.rightParen, 'Expected ")" after expression.');
      return value;
    }

    throw FormatException('Unexpected token: ${_peek.lexeme}');
  }

  double _applyFunction(String name, double value) {
    switch (name) {
      case 'sin':
        return sin(_angleValue(value));
      case 'cos':
        return cos(_angleValue(value));
      case 'tan':
        return tan(_angleValue(value));
      case 'asin':
        return _fromRadians(asin(value));
      case 'acos':
        return _fromRadians(acos(value));
      case 'atan':
        return _fromRadians(atan(value));
      case 'sqrt':
        if (value < 0) {
          throw const FormatException('Cannot take square root of a negative number.');
        }
        return sqrt(value);
      case 'log':
        if (value <= 0) {
          throw const FormatException('Logarithm only accepts positive numbers.');
        }
        return log(value) / ln10;
      case 'ln':
        if (value <= 0) {
          throw const FormatException('Natural log only accepts positive numbers.');
        }
        return log(value);
      default:
        throw FormatException('Unknown function: $name');
    }
  }

  double _factorial(double value) {
    if (value < 0 || value != value.roundToDouble()) {
      throw const FormatException('Factorial only accepts whole numbers.');
    }

    final whole = value.toInt();
    if (whole > 170) {
      throw const FormatException('Number too large for factorial.');
    }

    var result = 1.0;
    for (var index = 2; index <= whole; index++) {
      result *= index;
    }
    return result;
  }

  double _angleValue(double input) {
    if (!useDegrees) {
      return input;
    }
    return input * pi / 180;
  }

  double _fromRadians(double input) {
    if (!useDegrees) {
      return input;
    }
    return input * 180 / pi;
  }

  bool _match(_TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _matchOperator(String operator) {
    if (_check(_TokenType.operator) && _peek.lexeme == operator) {
      _advance();
      return true;
    }
    return false;
  }

  void _expect(_TokenType type, String message) {
    if (!_match(type)) {
      throw FormatException(message);
    }
  }

  bool _check(_TokenType type) => _peek.type == type;

  _Token get _peek => _tokens[_current];

  _Token get _previous => _tokens[_current - 1];

  void _advance() {
    if (_current < _tokens.length - 1) {
      _current++;
    }
  }
}
