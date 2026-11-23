/// Arithmetic for millimetres, coordinates and angles. No script evaluation.
double? calculate(String input) {
  final source = input
      .trim()
      .replaceAll(',', '.')
      .replaceAll('−', '-')
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
  if (source.isEmpty || source.length > 256) return null;
  try {
    final parser = _Arithmetic(source);
    final result = parser.sum();
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

  double sum() {
    var v = product();
    while (true) {
      if (take('+')) {
        v += product();
      } else if (take('-')) {
        v -= product();
      } else {
        return v;
      }
    }
  }

  double product() {
    var v = atom();
    while (true) {
      if (take('*')) {
        v *= atom();
      } else if (take('/')) {
        v /= atom();
      } else {
        return v;
      }
    }
  }

  double atom() {
    if (take('+')) return atom();
    if (take('-')) return -atom();
    if (take('(')) {
      final v = sum();
      if (!take(')')) throw const FormatException();
      return v;
    }
    final match = number.matchAsPrefix(text, cursor);
    if (match == null) throw const FormatException();
    cursor = match.end;
    return double.parse(match[0]!);
  }
}
