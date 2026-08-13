import 'token.dart';

class Lexer {
  final String source;
  int _pos = 0;
  int _line = 1;

  static final Map<String, TokenType> _keywords = {
    'function': TokenType.function,
    'var': TokenType.varKeyword,
    'return': TokenType.returnKeyword,
    'if': TokenType.ifKeyword,
    'else': TokenType.elseKeyword,
    'while': TokenType.whileKeyword,
    'for': TokenType.forKeyword,
    'true': TokenType.trueKeyword,
    'false': TokenType.falseKeyword,
    'null': TokenType.nullKeyword,
    'try': TokenType.tryKeyword,
    'catch': TokenType.catchKeyword,
    'finally': TokenType.finallyKeyword,
    'throw': TokenType.throwKeyword,
    'break': TokenType.breakKeyword,
    'continue': TokenType.continueKeyword,
  };

  Lexer(this.source);

  List<Token> tokenize() {
    final tokens = <Token>[];

    while (_pos < source.length) {
      final ch = source[_pos];

      if (ch == '\n') {
        _line++;
        _pos++;
        continue;
      }

      if (ch == ' ' || ch == '\t' || ch == '\r') {
        _pos++;
        continue;
      }

      if (ch == '/' && _pos + 1 < source.length && source[_pos + 1] == '/') {
        _skipComment();
        continue;
      }

      if (ch == '/' && _pos + 1 < source.length && source[_pos + 1] == '*') {
        _skipBlockComment();
        continue;
      }

      if (_isDigit(ch) || (ch == '.' && _pos + 1 < source.length && _isDigit(source[_pos + 1]))) {
        tokens.add(_readNumber());
        continue;
      }

      if (ch == '"' || ch == "'") {
        tokens.addAll(_readString(ch, true));
        continue;
      }

      if (_isAlpha(ch)) {
        tokens.add(_readIdentifier());
        continue;
      }

      if (ch == '(') {
        _pos++;
        tokens.add(Token(TokenType.leftParen, '(', _line));
        continue;
      }
      if (ch == ')') {
        _pos++;
        tokens.add(Token(TokenType.rightParen, ')', _line));
        continue;
      }
      if (ch == '{') {
        _pos++;
        tokens.add(Token(TokenType.leftBrace, '{', _line));
        continue;
      }
      if (ch == '}') {
        _pos++;
        tokens.add(Token(TokenType.rightBrace, '}', _line));
        continue;
      }
      if (ch == '[') {
        _pos++;
        tokens.add(Token(TokenType.leftBracket, '[', _line));
        continue;
      }
      if (ch == ']') {
        _pos++;
        tokens.add(Token(TokenType.rightBracket, ']', _line));
        continue;
      }
      if (ch == ',') {
        _pos++;
        tokens.add(Token(TokenType.comma, ',', _line));
        continue;
      }
      if (ch == ';') {
        _pos++;
        tokens.add(Token(TokenType.semicolon, ';', _line));
        continue;
      }
      if (ch == ':') {
        _pos++;
        tokens.add(Token(TokenType.colon, ':', _line));
        continue;
      }
      if (ch == '.') {
        _pos++;
        tokens.add(Token(TokenType.dot, '.', _line));
        continue;
      }

      if (ch == '+') {
        if (_pos + 1 < source.length && source[_pos + 1] == '+') {
          _pos += 2;
          tokens.add(Token(TokenType.plusPlus, '++', _line));
        } else {
          _pos++;
          tokens.add(Token(TokenType.plus, '+', _line));
        }
        continue;
      }
      if (ch == '-') {
        if (_pos + 1 < source.length && source[_pos + 1] == '-') {
          _pos += 2;
          tokens.add(Token(TokenType.minusMinus, '--', _line));
        } else {
          _pos++;
          tokens.add(Token(TokenType.minus, '-', _line));
        }
        continue;
      }
      if (ch == '*') {
        _pos++;
        tokens.add(Token(TokenType.star, '*', _line));
        continue;
      }
      if (ch == '%') {
        _pos++;
        tokens.add(Token(TokenType.percent, '%', _line));
        continue;
      }

      if (ch == '=' && _pos + 1 < source.length && source[_pos + 1] == '=') {
        _pos += 2;
        tokens.add(Token(TokenType.equalEqual, '==', _line));
        continue;
      }
      if (ch == '!' && _pos + 1 < source.length && source[_pos + 1] == '=') {
        _pos += 2;
        tokens.add(Token(TokenType.notEqual, '!=', _line));
        continue;
      }
      if (ch == '<' && _pos + 1 < source.length && source[_pos + 1] == '=') {
        _pos += 2;
        tokens.add(Token(TokenType.lessEqual, '<=', _line));
        continue;
      }
      if (ch == '>' && _pos + 1 < source.length && source[_pos + 1] == '=') {
        _pos += 2;
        tokens.add(Token(TokenType.greaterEqual, '>=', _line));
        continue;
      }
      if (ch == '&' && _pos + 1 < source.length && source[_pos + 1] == '&') {
        _pos += 2;
        tokens.add(Token(TokenType.and, '&&', _line));
        continue;
      }
      if (ch == '|' && _pos + 1 < source.length && source[_pos + 1] == '|') {
        _pos += 2;
        tokens.add(Token(TokenType.or, '||', _line));
        continue;
      }

      if (ch == '<') {
        _pos++;
        tokens.add(Token(TokenType.less, '<', _line));
        continue;
      }
      if (ch == '>') {
        _pos++;
        tokens.add(Token(TokenType.greater, '>', _line));
        continue;
      }
      if (ch == '!') {
        _pos++;
        tokens.add(Token(TokenType.not, '!', _line));
        continue;
      }
      if (ch == '/') {
        _pos++;
        tokens.add(Token(TokenType.slash, '/', _line));
        continue;
      }
      if (ch == '=') {
        _pos++;
        tokens.add(Token(TokenType.assign, '=', _line));
        continue;
      }
      if (ch == '?') {
        _pos++;
        tokens.add(Token(TokenType.question, '?', _line));
        continue;
      }

      throw Exception('Unexpected character "$ch" at line $_line');
    }

    tokens.add(Token(TokenType.eof, null, _line));
    return tokens;
  }

  void _skipComment() {
    while (_pos < source.length && source[_pos] != '\n') {
      _pos++;
    }
  }

  void _skipBlockComment() {
    _pos += 2;
    while (_pos < source.length - 1) {
      if (source[_pos] == '*' && source[_pos + 1] == '/') {
        _pos += 2;
        return;
      }
      if (source[_pos] == '\n') _line++;
      _pos++;
    }
  }

  Token _readNumber() {
    final start = _pos;
    bool hasDot = false;

    while (_pos < source.length && (_isDigit(source[_pos]) || source[_pos] == '.')) {
      if (source[_pos] == '.') {
        if (hasDot) break;
        hasDot = true;
      }
      _pos++;
    }

    final numStr = source.substring(start, _pos);
    final num value = hasDot ? double.parse(numStr) : int.parse(numStr);
    return Token(TokenType.number, value, _line);
  }

  List<Token> _readString(String quote, bool isFirstOfInterpolation) {
    _pos++;
    final tokens = <Token>[];
    var start = _pos;
    var hasInterpolation = false;

    while (_pos < source.length && source[_pos] != quote) {
      if (source[_pos] == '\\') {
        _pos++;
        if (_pos < source.length) _pos++;
        continue;
      }
      if (_pos >= source.length) break;
      if (source[_pos] == '\x24') {
        hasInterpolation = true;
        final part = _processEscapes(source.substring(start, _pos));
        if (isFirstOfInterpolation) {
          tokens.add(Token(TokenType.stringStart, part, _line));
        } else {
          if (part.isNotEmpty) tokens.add(Token(TokenType.stringPart, part, _line));
        }
        tokens.add(Token(TokenType.dollar, '\x24', _line));
        _pos++;
        if (_pos < source.length && source[_pos] == '{') {
          _pos++;
          tokens.add(Token(TokenType.leftBrace, '{', _line));
          int depth = 1;
          final exprStart = _pos;
          while (_pos < source.length && depth > 0) {
            if (source[_pos] == '{') {
              depth++;
            } else if (source[_pos] == '}') {
              depth--;
            }
            if (depth > 0) _pos++;
          }
          final expr = source.substring(exprStart, _pos);
          final subLexer = Lexer(expr);
          for (final t in subLexer.tokenize()) {
            if (t.type != TokenType.eof) tokens.add(t);
          }
          tokens.add(Token(TokenType.rightBrace, '}', _line));
          _pos++;
          start = _pos;
        } else {
          final idStart = _pos;
          while (_pos < source.length && (_isAlphaNumeric(source[_pos]) || source[_pos] == '_')) {
            _pos++;
          }
          tokens.add(Token(TokenType.identifier, source.substring(idStart, _pos), _line));
          start = _pos;
        }
      } else {
        _pos++;
      }
    }

    if (!hasInterpolation) {
      final str = _processEscapes(source.substring(start, _pos));
      _pos++;
      return [Token(TokenType.string, str, _line)];
    }

    final remaining = _processEscapes(source.substring(start, _pos));
    tokens.add(Token(TokenType.stringEnd, remaining, _line));
    if (_pos < source.length) _pos++;
    return tokens;
  }

  String _processEscapes(String str) {
    final buf = StringBuffer();
    var i = 0;
    while (i < str.length) {
      if (str[i] == '\\' && i + 1 < str.length) {
        i++;
        switch (str[i]) {
          case 'n':
            buf.write('\n');
            break;
          case 't':
            buf.write('\t');
            break;
          case 'r':
            buf.write('\r');
            break;
          case '\\':
            buf.write('\\');
            break;
          case "'":
            buf.write("'");
            break;
          case '"':
            buf.write('"');
            break;
          case '\x24':
            buf.write('\x24');
            break;
          default:
            buf.write(str[i]);
        }
      } else {
        buf.write(str[i]);
      }
      i++;
    }
    return buf.toString();
  }

  Token _readIdentifier() {
    final start = _pos;

    while (_pos < source.length && (_isAlphaNumeric(source[_pos]) || source[_pos] == '_')) {
      _pos++;
    }

    final word = source.substring(start, _pos);
    final type = _keywords[word] ?? TokenType.identifier;
    return Token(type, word, _line);
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  bool _isAlpha(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95;
  }

  bool _isAlphaNumeric(String ch) => _isAlpha(ch) || _isDigit(ch);
}
