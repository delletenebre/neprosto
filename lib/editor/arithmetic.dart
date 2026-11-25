String _normalizeNumber(String input) =>
    input.trim().replaceAll(',', '.').replaceAll('−', '-');

bool isNumberLiteral(String input) =>
    double.tryParse(_normalizeNumber(input)) != null;

/// Arithmetic for numeric inputs, with optional grouping by whitespace.
double? calculate(String input) {
  final source = _normalizeNumber(input)
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
  if (source.isEmpty || source.length > 256) return null;
  try {
    final parser = _Arithmetic(source);
    final result = parser.expression();
    parser.space();
    return parser.cursor == source.length && result.isFinite ? result : null;
  } on FormatException {
    return null;
  }
}

class _Arithmetic {
  final String text;
  int cursor = 0;
  _Arithmetic(this.text);
  static final number = RegExp(r'(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?');
  void space() {
    while (cursor < text.length && text.codeUnitAt(cursor) <= 32) {
      cursor++;
    }
  }

  bool take(String token) {
    space();
    if (!text.startsWith(token, cursor)) return false;
    cursor++;
    return true;
  }

  // Tight operators bind before spaced operators. Within either group,
  // multiplication and division still bind before addition and subtraction.
  double expression([int minimum = 1]) {
    var value = atom();
    while (cursor < text.length) {
      final endOfOperand = cursor;
      space();
      if (cursor == text.length) break;
      final operator = text[cursor];
      final rank = switch (operator) {
        '+' || '-' => 1,
        '*' || '/' => 2,
        _ => 0,
      };
      if (rank == 0) break;
      final spaced =
          cursor != endOfOperand ||
          (cursor + 1 < text.length && text.codeUnitAt(cursor + 1) <= 32);
      final precedence = spaced ? rank : rank + 2;
      if (precedence < minimum) {
        cursor = endOfOperand;
        break;
      }
      cursor++;
      final right = expression(precedence + 1);
      value = switch (operator) {
        '+' => value + right,
        '-' => value - right,
        '*' => value * right,
        _ => value / right,
      };
      if (!value.isFinite) throw const FormatException();
    }
    return value;
  }

  double atom() {
    if (take('+')) return atom();
    if (take('-')) return -atom();
    if (take('(')) {
      final v = expression();
      if (!take(')')) throw const FormatException();
      return v;
    }
    final match = number.matchAsPrefix(text, cursor);
    if (match == null) throw const FormatException();
    cursor = match.end;
    return double.parse(match[0]!);
  }
}
