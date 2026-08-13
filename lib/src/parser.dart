import 'token.dart';
import 'ast.dart';

class Parser {
  final List<Token> tokens;
  int _pos = 0;

  Parser(this.tokens);

  List<AstNode> parse() {
    final statements = <AstNode>[];
    while (!(_current().type == TokenType.eof)) {
      statements.add(_parseStatement());
    }
    return statements;
  }

  Token _current() => tokens[_pos];

  Token _advance() {
    final token = tokens[_pos];
    _pos++;
    return token;
  }

  Token _expect(TokenType type) {
    final token = _current();
    if (token.type != type) {
      throw Exception('Expected $type but got ${token.type} at line ${token.line}');
    }
    return _advance();
  }

  AstNode _parseStatement() {
    final token = _current();

    if (token.type == TokenType.function) return _parseFunctionDef();
    if (token.type == TokenType.varKeyword) return _parseVarDecl();
    if (token.type == TokenType.returnKeyword) return _parseReturn();
    if (token.type == TokenType.ifKeyword) return _parseIf();
    if (token.type == TokenType.whileKeyword) return _parseWhile();
    if (token.type == TokenType.forKeyword) return _parseFor();
    if (token.type == TokenType.tryKeyword) return _parseTryCatch();
    if (token.type == TokenType.throwKeyword) return _parseThrow();
    if (token.type == TokenType.breakKeyword) {
      _advance();
      if (_current().type == TokenType.semicolon) _advance();
      return BreakStatement();
    }
    if (token.type == TokenType.continueKeyword) {
      _advance();
      if (_current().type == TokenType.semicolon) _advance();
      return ContinueStatement();
    }
    if (token.type == TokenType.leftBrace) return Block(_parseBlock());

    final expr = _parseExpression();
    if (_current().type == TokenType.semicolon) _advance();
    return ExpressionStatement(expr);
  }

  List<AstNode> _parseBlock() {
    _expect(TokenType.leftBrace);
    final statements = <AstNode>[];
    while (_current().type != TokenType.rightBrace) {
      statements.add(_parseStatement());
    }
    _expect(TokenType.rightBrace);
    return statements;
  }

  FunctionDefinition _parseFunctionDef() {
    _advance();
    String? name;
    if (_current().type == TokenType.identifier) {
      name = _advance().value as String;
    }
    _expect(TokenType.leftParen);
    final params = <String>[];

    if (_current().type != TokenType.rightParen) {
      params.add(_expect(TokenType.identifier).value as String);
      while (_current().type == TokenType.comma) {
        _advance();
        params.add(_expect(TokenType.identifier).value as String);
      }
    }
    _expect(TokenType.rightParen);
    final body = _parseBlock();
    return FunctionDefinition(name, params, body);
  }

  VarDeclaration _parseVarDecl() {
    _advance();
    final name = _expect(TokenType.identifier).value as String;
    AstNode? init;
    if (_current().type == TokenType.assign) {
      _advance();
      init = _parseExpression();
    }
    if (_current().type == TokenType.semicolon) _advance();
    return VarDeclaration(name, init);
  }

  ReturnStatement _parseReturn() {
    _advance();
    AstNode? value;
    if (_current().type != TokenType.semicolon && _current().type != TokenType.rightBrace) {
      value = _parseExpression();
    }
    if (_current().type == TokenType.semicolon) _advance();
    return ReturnStatement(value);
  }

  IfStatement _parseIf() {
    _advance();
    _expect(TokenType.leftParen);
    final condition = _parseExpression();
    _expect(TokenType.rightParen);
    final thenBranch = _parseBlock();
    List<AstNode>? elseBranch;
    if (_current().type == TokenType.elseKeyword) {
      _advance();
      if (_current().type == TokenType.ifKeyword) {
        elseBranch = [_parseIf()];
      } else {
        elseBranch = _parseBlock();
      }
    }
    return IfStatement(condition, thenBranch, elseBranch);
  }

  WhileStatement _parseWhile() {
    _advance();
    _expect(TokenType.leftParen);
    final condition = _parseExpression();
    _expect(TokenType.rightParen);
    final body = _parseBlock();
    return WhileStatement(condition, body);
  }

  ForStatement _parseFor() {
    _advance();
    _expect(TokenType.leftParen);

    AstNode? initializer;
    if (_current().type == TokenType.varKeyword) {
      initializer = _parseVarDecl();
    } else if (_current().type != TokenType.semicolon) {
      initializer = _parseExpression();
      if (_current().type == TokenType.semicolon) _advance();
    } else {
      _advance();
    }

    AstNode? condition;
    if (_current().type != TokenType.semicolon) {
      condition = _parseExpression();
    }
    _expect(TokenType.semicolon);

    AstNode? update;
    if (_current().type != TokenType.rightParen) {
      update = _parseExpression();
    }
    _expect(TokenType.rightParen);

    final body = _parseBlock();
    return ForStatement(initializer, condition, update, body);
  }

  TryCatchStatement _parseTryCatch() {
    _advance();
    final tryBlock = _parseBlock();

    String? catchVar;
    List<AstNode>? catchBlock;
    if (_current().type == TokenType.catchKeyword) {
      _advance();
      _expect(TokenType.leftParen);
      catchVar = _expect(TokenType.identifier).value as String;
      _expect(TokenType.rightParen);
      catchBlock = _parseBlock();
    }

    List<AstNode>? finallyBlock;
    if (_current().type == TokenType.finallyKeyword) {
      _advance();
      finallyBlock = _parseBlock();
    }

    if (catchBlock == null && finallyBlock == null) {
      throw Exception('try block must have catch or finally at line ${_current().line}');
    }

    return TryCatchStatement(tryBlock, catchVar, catchBlock, finallyBlock);
  }

  ThrowStatement _parseThrow() {
    _advance();
    AstNode? value;
    if (_current().type != TokenType.semicolon && _current().type != TokenType.rightBrace) {
      value = _parseExpression();
    }
    if (_current().type == TokenType.semicolon) _advance();
    return ThrowStatement(value);
  }

  AstNode _parseExpression() => _parseAssignment();

  InterpolatedString _parseInterpolatedString() {
    final parts = <AstNode>[];

    while (_current().type != TokenType.eof) {
      final token = _current();

      if (token.type == TokenType.stringStart) {
        _advance();
        final value = token.value as String;
        if (value.isNotEmpty) {
          parts.add(StringLiteral(value));
        }
      } else if (token.type == TokenType.stringPart) {
        _advance();
        final value = token.value as String;
        if (value.isNotEmpty) {
          parts.add(StringLiteral(value));
        }
      } else if (token.type == TokenType.stringEnd) {
        _advance();
        final value = token.value as String;
        if (value.isNotEmpty) {
          parts.add(StringLiteral(value));
        }
        break;
      } else if (token.type == TokenType.dollar) {
        _advance();
        if (_current().type == TokenType.leftBrace) {
          _advance();
          final expr = _parseExpression();
          _expect(TokenType.rightBrace);
          parts.add(expr);
        } else if (_current().type == TokenType.identifier) {
          parts.add(Identifier(_advance().value as String));
        } else {
          throw Exception(r'Expected identifier or { after $ at line ' + token.line.toString());
        }
      } else {
        break;
      }
    }

    return InterpolatedString(parts);
  }

  AstNode _parseAssignment() {
    final expr = _parseTernary();

    if (expr is Identifier && _current().type == TokenType.assign) {
      _advance();
      final value = _parseAssignment();
      return Assignment(expr.name, value);
    }
    return expr;
  }

  AstNode _parseTernary() {
    final condition = _parseLogicalOr();
    if (_current().type == TokenType.question) {
      _advance();
      final trueBranch = _parseAssignment();
      _expect(TokenType.colon);
      final falseBranch = _parseAssignment();
      return TernaryExpression(condition, trueBranch, falseBranch);
    }
    return condition;
  }

  AstNode _parseLogicalOr() {
    var expr = _parseLogicalAnd();
    while (_current().type == TokenType.or) {
      _advance();
      expr = BinaryExpression(expr, '||', _parseLogicalAnd());
    }
    return expr;
  }

  AstNode _parseLogicalAnd() {
    var expr = _parseEquality();
    while (_current().type == TokenType.and) {
      _advance();
      expr = BinaryExpression(expr, '&&', _parseEquality());
    }
    return expr;
  }

  AstNode _parseEquality() {
    var expr = _parseComparison();
    while (_current().type == TokenType.equalEqual || _current().type == TokenType.notEqual) {
      final op = _advance();
      expr = BinaryExpression(expr, op.type == TokenType.equalEqual ? '==' : '!=', _parseComparison());
    }
    return expr;
  }

  AstNode _parseComparison() {
    var expr = _parseTerm();
    while (_current().type == TokenType.less ||
        _current().type == TokenType.greater ||
        _current().type == TokenType.lessEqual ||
        _current().type == TokenType.greaterEqual) {
      final op = _advance();
      String symbol;
      switch (op.type) {
        case TokenType.less:
          symbol = '<';
          break;
        case TokenType.greater:
          symbol = '>';
          break;
        case TokenType.lessEqual:
          symbol = '<=';
          break;
        case TokenType.greaterEqual:
          symbol = '>=';
          break;
        default:
          throw StateError('Unexpected operator');
      }
      expr = BinaryExpression(expr, symbol, _parseTerm());
    }
    return expr;
  }

  AstNode _parseTerm() {
    var expr = _parseFactor();
    while (_current().type == TokenType.plus || _current().type == TokenType.minus) {
      final op = _advance();
      expr = BinaryExpression(expr, op.type == TokenType.plus ? '+' : '-', _parseFactor());
    }
    return expr;
  }

  AstNode _parseFactor() {
    var expr = _parseUnary();
    while (_current().type == TokenType.star || _current().type == TokenType.slash || _current().type == TokenType.percent) {
      final op = _advance();
      String symbol;
      switch (op.type) {
        case TokenType.star:
          symbol = '*';
          break;
        case TokenType.slash:
          symbol = '/';
          break;
        case TokenType.percent:
          symbol = '%';
          break;
        default:
          throw StateError('Unexpected operator');
      }
      expr = BinaryExpression(expr, symbol, _parseUnary());
    }
    return expr;
  }

  AstNode _parseUnary() {
    if (_current().type == TokenType.plus || _current().type == TokenType.minus || _current().type == TokenType.not) {
      final op = _advance();
      final symbol = op.type == TokenType.plus
          ? '+'
          : op.type == TokenType.minus
          ? '-'
          : '!';
      return UnaryExpression(symbol, _parseUnary());
    }
    return _parsePrimary();
  }

  AstNode _parsePrimary() {
    final token = _current();

    AstNode base;

    if (token.type == TokenType.function) {
      return _parseFunctionDef();
    }
    if (token.type == TokenType.number) {
      _advance();
      base = NumberLiteral(token.value as num);
    } else if (token.type == TokenType.string) {
      _advance();
      base = StringLiteral(token.value as String);
    } else if (token.type == TokenType.stringStart || token.type == TokenType.stringEnd) {
      base = _parseInterpolatedString();
    } else if (token.type == TokenType.trueKeyword) {
      _advance();
      base = BooleanLiteral(true);
    } else if (token.type == TokenType.falseKeyword) {
      _advance();
      base = BooleanLiteral(false);
    } else if (token.type == TokenType.nullKeyword) {
      _advance();
      base = NullLiteral();
    } else if (token.type == TokenType.identifier) {
      final name = _advance().value as String;
      base = Identifier(name);
    } else if (token.type == TokenType.leftParen) {
      _advance();
      base = _parseExpression();
      _expect(TokenType.rightParen);
    } else if (token.type == TokenType.leftBrace) {
      _advance();
      final props = <String, AstNode>{};
      while (_current().type != TokenType.rightBrace) {
        final key = _expect(TokenType.identifier).value as String;
        _expect(TokenType.colon);
        props[key] = _parseExpression();
        if (_current().type == TokenType.comma) _advance();
      }
      _expect(TokenType.rightBrace);
      base = ObjectLiteral(props);
    } else if (token.type == TokenType.leftBracket) {
      _advance();
      final elems = <AstNode>[];
      while (_current().type != TokenType.rightBracket) {
        elems.add(_parseExpression());
        if (_current().type == TokenType.comma) _advance();
      }
      _expect(TokenType.rightBracket);
      base = ArrayLiteral(elems);
    } else {
      throw Exception('Unexpected token ${token.type} at line ${token.line}');
    }

    while (true) {
      if (_current().type == TokenType.leftParen) {
        _advance();
        final args = <AstNode>[];
        if (_current().type != TokenType.rightParen) {
          args.add(_parseExpression());
          while (_current().type == TokenType.comma) {
            _advance();
            args.add(_parseExpression());
          }
        }
        _expect(TokenType.rightParen);
        base = FunctionCall(base, args);
        continue;
      }

      if (_current().type == TokenType.dot) {
        _advance();
        final property = Identifier(_expect(TokenType.identifier).value as String);
        base = PropertyAccess(base, property);
        if (_current().type == TokenType.leftParen) {
          _advance();
          final args = <AstNode>[];
          if (_current().type != TokenType.rightParen) {
            args.add(_parseExpression());
            while (_current().type == TokenType.comma) {
              _advance();
              args.add(_parseExpression());
            }
          }
          _expect(TokenType.rightParen);
          base = FunctionCall(base, args);
        }
        continue;
      }

      if (_current().type == TokenType.leftBracket) {
        _advance();
        final property = _parseExpression();
        _expect(TokenType.rightBracket);
        base = PropertyAccess(base, property, isBracket: true);
        continue;
      }

      break;
    }

    while (_current().type == TokenType.plusPlus || _current().type == TokenType.minusMinus) {
      final op = _advance();
      base = UnaryExpression(op.type == TokenType.plusPlus ? 'postfix++' : 'postfix--', base);
    }

    return base;
  }
}
