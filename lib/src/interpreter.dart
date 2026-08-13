import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as dart_math;

import 'ast.dart';
import 'lexer.dart';
import 'parser.dart';
import 'environment.dart';
import 'context.dart';

class ReturnException {
  final dynamic value;
  ReturnException(this.value);
}

class BreakException {}

class ContinueException {}

class ThrowException {
  final dynamic value;
  ThrowException(this.value);
}

class NativeFunctionReturn {
  final dynamic value;
  final bool handled;

  NativeFunctionReturn(this.value, {this.handled = true});

  NativeFunctionReturn.ok(this.value) : handled = true;
  NativeFunctionReturn.skip() : value = null, handled = false;
}

typedef CommandHandler = NativeFunctionReturn Function(String cmd, Map<String, dynamic> params);

Interpreter runScript(String source, {Map<String, dynamic> variables = const {}, CommandHandler? onUnknownFunction, DartJSContext? context}) {
  final env = context?.env;
  final interpreter = Interpreter(onUnknownFunction, env);

  // Merge provided variables into the context/environment or interpreter globals
  if (context != null) {
    for (final entry in variables.entries) {
      context.set(entry.key, entry.value);
    }
  } else {
    for (final entry in variables.entries) {
      interpreter.setGlobal(entry.key, entry.value);
    }
  }

  final tokens = Lexer(source).tokenize();
  final ast = Parser(tokens).parse();
  interpreter.run(ast);
  return interpreter;
}

class Interpreter {
  final Environment _globalEnv;
  final dart_math.Random _random = dart_math.Random();
  final CommandHandler? _onCommand;
  final List<Future<dynamic>> _pendingAsyncTasks = [];

  Interpreter([this._onCommand, Environment? initialGlobal]) : _globalEnv = initialGlobal ?? Environment() {
    _registerBuiltins();
  }

  void _registerBuiltins() {
    _globalEnv.define('print', (List<dynamic> args) {
      final parts = args.map((a) {
        if (a is Map) return _stringifyObject(a);
        if (a is List) return a.map((e) => e is Map ? _stringifyObject(e) : _displayValue(e)).join(',');
        return _displayValue(a);
      });
      stdout.writeln(parts.join(' '));
      return null;
    });

    _globalEnv.define('random', (List<dynamic> args) {
      if (args.length != 2) throw Exception('random() expects 2 arguments');
      final min = (args[0] as num).toInt();
      final max = (args[1] as num).toInt();
      return min + _random.nextInt(max - min + 1);
    });

    final http = <String, dynamic>{
      'get': (List<dynamic> args) => _httpRequest('GET', args),
      'post': (List<dynamic> args) => _httpRequest('POST', args),
      'getJson': (List<dynamic> args) => _httpJsonRequest('GET', args),
      'postJson': (List<dynamic> args) => _httpJsonRequest('POST', args),
    };
    _globalEnv.define('http', http);

    _globalEnv.define('setTimeOut', (List<dynamic> args) {
      if (args.length < 2) throw Exception('setTimeOut() expects 2 arguments');
      final callback = args[0];
      final delay = (args[1] as num).toInt();

      Timer(Duration(milliseconds: delay), () {
        if (callback is Map && callback['type'] == 'function') {
          final funcDef = callback['def'] as FunctionDefinition;
          final funcEnv = Environment(callback['env'] as Environment);
          try {
            _executeBlock(funcDef.body, funcEnv);
          } on ReturnException catch (_) {}
        } else if (callback is Function) {
          Function.apply(callback, const []);
        }
      });

      return null;
    });

    _globalEnv.define('parseInt', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('parseInt() expects 1 argument');
      final val = args[0];
      if (val is num) return val.toInt();
      return int.parse(val.toString());
    });

    _globalEnv.define('toString', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('toString() expects 1 argument');
      return args[0].toString();
    });

    _globalEnv.define('split', (List<dynamic> args) {
      if (args.length < 2) throw Exception('split() expects 2 arguments');
      final delimiter = args[0].toString();
      final str = args[1].toString();
      return str.split(delimiter).toList();
    });

    _globalEnv.define('length', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('length() expects 1 argument');
      final val = args[0];
      if (val is String) return val.length;
      if (val is List) return val.length;
      if (val is Map) return val.length;
      return val.toString().length;
    });

    _globalEnv.define('substr', (List<dynamic> args) {
      if (args.length < 3) throw Exception('substr() expects 3 arguments');
      final start = (args[0] as num).toInt();
      final len = (args[1] as num).toInt();
      final str = args[2].toString();
      final end = start + len;
      return str.substring(start, end > str.length ? str.length : end);
    });

    _globalEnv.define('json', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('json() expects 1 argument');
      final str = args[0].toString();
      try {
        final decoded = jsonDecode(str);
        return _convertJsonValue(decoded);
      } catch (e) {
        throw Exception('json() parse error: $e');
      }
    });

    _globalEnv.define('jsonEncode', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('jsonEncode() expects 1 argument');
      return jsonEncode(args[0]);
    });

    _globalEnv.define('trim', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('trim() expects 1 argument');
      return args[0].toString().trim();
    });

    _globalEnv.define('toUpperCase', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('toUpperCase() expects 1 argument');
      return args[0].toString().toUpperCase();
    });

    _globalEnv.define('toLowerCase', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('toLowerCase() expects 1 argument');
      return args[0].toString().toLowerCase();
    });

    _globalEnv.define('contains', (List<dynamic> args) {
      if (args.length < 2) throw Exception('contains() expects 2 arguments');
      return args[0].toString().contains(args[1].toString());
    });

    _globalEnv.define('replace', (List<dynamic> args) {
      if (args.length < 3) throw Exception('replace() expects 3 arguments');
      return args[0].toString().replaceAll(args[1].toString(), args[2].toString());
    });

    _globalEnv.define('sin', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('sin() expects 1 argument');
      return dart_math.sin((args[0] as num).toDouble());
    });

    _globalEnv.define('cos', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('cos() expects 1 argument');
      return dart_math.cos((args[0] as num).toDouble());
    });

    _globalEnv.define('sqrt', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('sqrt() expects 1 argument');
      return dart_math.sqrt((args[0] as num).toDouble());
    });

    _globalEnv.define('abs', (List<dynamic> args) {
      if (args.isEmpty) throw Exception('abs() expects 1 argument');
      final val = args[0] as num;
      return val < 0 ? -val : val;
    });

    _globalEnv.define('PI', dart_math.pi);
    _globalEnv.define('SQRT2', dart_math.sqrt2);
    _globalEnv.define('E', dart_math.e);
  }

  dynamic _httpRequest(String method, List<dynamic> args) {
    if (args.isEmpty) throw Exception('http.$method() expects a URL');

    final url = args[0].toString();
    var headers = <String, String>{};
    dynamic body;
    dynamic query;
    dynamic successCallback;
    dynamic errorCallback;

    for (final arg in args.skip(1)) {
      if (arg is Map && arg['type'] == 'function') {
        if (successCallback == null) {
          successCallback = arg;
        } else {
          errorCallback = arg;
        }
      } else if (arg is Map) {
        if (_looksLikeHeaders(arg)) {
          headers = _normalizeHeaders(arg);
        } else if (query == null) {
          query = arg;
        }
      } else if (arg is Function) {
        if (successCallback == null) {
          successCallback = arg;
        } else {
          errorCallback = arg;
        }
      } else {
        if (body == null) {
          body = arg;
        }
      }
    }

    final finalUrl = _buildUrl(url, query);

    if (successCallback != null || errorCallback != null) {
      return _httpRequestAsync(method, finalUrl, headers, body, successCallback, errorCallback);
    }

    final arguments = <String>[];
    arguments.addAll(['-sS', '-L']);

    if (method == 'POST') {
      arguments.addAll(['-X', 'POST']);
    }

    for (final entry in headers.entries) {
      arguments.addAll(['-H', '${entry.key}: ${entry.value}']);
    }

    if (body != null) {
      final encoded = body is Map || body is List ? jsonEncode(body) : body.toString();
      arguments.addAll(['--data', encoded]);
    }

    arguments.add(finalUrl);

    final result = Process.runSync('curl', arguments);
    if (result.exitCode != 0) {
      final error = result.stderr.toString().trim();
      throw Exception('http.$method() failed: ${error.isNotEmpty ? error : 'curl exit ${result.exitCode}'}');
    }

    return result.stdout.toString();
  }

  dynamic _httpRequestAsync(String method, String url, Map<String, String> headers, dynamic body, dynamic successCallback, dynamic errorCallback) {
    final task = Future(() async {
      try {
        final arguments = <String>[];
        arguments.addAll(['-sS', '-L']);
        if (method == 'POST') {
          arguments.addAll(['-X', 'POST']);
        }
        for (final entry in headers.entries) {
          arguments.addAll(['-H', '${entry.key}: ${entry.value}']);
        }
        if (body != null) {
          final encoded = body is Map || body is List ? jsonEncode(body) : body.toString();
          arguments.addAll(['--data', encoded]);
        }
        arguments.add(url);

        final result = await Process.run('curl', arguments);
        if (result.exitCode != 0) {
          final error = result.stderr.toString().trim();
          if (errorCallback != null) {
            if (errorCallback is Function) {
              Function.apply(errorCallback, [error, result.exitCode]);
            }
          }
          return;
        }

        if (successCallback != null) {
          final payload = result.stdout.toString();
          try {
            final parsed = jsonDecode(payload);
            _invokeCallable(successCallback, [parsed]);
          } catch (_) {
            _invokeCallable(successCallback, [payload]);
          }
        }
      } catch (e) {
        if (errorCallback != null) {
          _invokeCallable(errorCallback, [e.toString(), -1]);
        }
      }
    });

    _pendingAsyncTasks.add(task);
    task.whenComplete(() => _pendingAsyncTasks.remove(task));
    return null;
  }

  dynamic _invokeCallable(dynamic callable, List<dynamic> args) {
    if (callable is Map && callable['type'] == 'function') {
      final funcDef = callable['def'] as FunctionDefinition;
      final funcEnv = Environment(callable['env'] as Environment);
      for (var i = 0; i < funcDef.parameters.length; i++) {
        funcEnv.define(funcDef.parameters[i], i < args.length ? args[i] : null);
      }
      try {
        _executeBlock(funcDef.body, funcEnv);
        return null;
      } on ReturnException catch (e) {
        return e.value;
      }
    }

    if (callable is Function) {
      return Function.apply(callable, [args]);
    }

    return null;
  }

  Future<void> waitForPendingAsyncTasks() async {
    if (_pendingAsyncTasks.isEmpty) return;
    await Future.wait(_pendingAsyncTasks);
  }

  dynamic _httpJsonRequest(String method, List<dynamic> args) {
    final raw = _httpRequest(method, args);
    if (raw is! String || raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      throw Exception('http.$method() response is not valid JSON');
    }
  }

  Map<String, String> _normalizeHeaders(Map<dynamic, dynamic> headers) {
    final result = <String, String>{};
    for (final entry in headers.entries) {
      result[entry.key.toString()] = entry.value.toString();
    }
    return result;
  }

  bool _looksLikeHeaders(Map<dynamic, dynamic> value) {
    if (value.isEmpty) return false;
    final keys = value.keys.map((e) => e.toString()).toList();
    final headerPatterns = <String>{'authorization', 'accept', 'content-type', 'user-agent', 'x-api-key', 'cookie', 'cache-control', 'token'};
    return keys.any((key) => headerPatterns.contains(key.toLowerCase()) || key.contains('-'));
  }

  String _buildUrl(String url, dynamic query) {
    if (query == null) return url;
    if (query is! Map) return url;
    final entries = query.entries
        .map((entry) {
          final key = Uri.encodeQueryComponent(entry.key.toString());
          final value = Uri.encodeQueryComponent(entry.value.toString());
          return '$key=$value';
        })
        .join('&');

    if (entries.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url$separator$entries';
  }

  void run(List<AstNode> statements) {
    _executeBlock(statements, _globalEnv);
  }

  void setGlobal(String name, dynamic value) {
    _globalEnv.define(name, value);
  }

  dynamic getGlobal(String name) => _globalEnv.get(name);

  void _executeBlock(List<AstNode> statements, Environment env) {
    for (final stmt in statements) {
      _execute(stmt, env);
    }
  }

  void _execute(AstNode node, Environment env) {
    if (node is FunctionDefinition) {
      final funcObj = {'type': 'function', 'def': node, 'env': env};
      if (node.name != null) {
        env.define(node.name!, funcObj);
      }
    } else if (node is VarDeclaration) {
      final value = node.initializer != null ? _evaluate(node.initializer!, env) : null;
      env.define(node.name, value);
    } else if (node is Assignment) {
      final value = _evaluate(node.value, env);
      env.set(node.name, value);
    } else if (node is ReturnStatement) {
      final value = node.value != null ? _evaluate(node.value!, env) : null;
      throw ReturnException(value);
    } else if (node is IfStatement) {
      final condition = _evaluate(node.condition, env);
      if (_isTruthy(condition)) {
        final blockEnv = Environment(env);
        _executeBlock(node.thenBranch, blockEnv);
      } else if (node.elseBranch != null) {
        final blockEnv = Environment(env);
        _executeBlock(node.elseBranch!, blockEnv);
      }
    } else if (node is WhileStatement) {
      while (_isTruthy(_evaluate(node.condition, env))) {
        final blockEnv = Environment(env);
        try {
          _executeBlock(node.body, blockEnv);
        } on BreakException {
          break;
        } on ContinueException {
          continue;
        }
      }
    } else if (node is ForStatement) {
      final forEnv = Environment(env);
      if (node.initializer != null) _execute(node.initializer!, forEnv);
      while (node.condition == null || _isTruthy(_evaluate(node.condition!, forEnv))) {
        final loopEnv = Environment(forEnv);
        try {
          _executeBlock(node.body, loopEnv);
        } on BreakException {
          break;
        } on ContinueException {
          // continue
        }
        if (node.update != null) _evaluate(node.update!, forEnv);
      }
    } else if (node is BreakStatement) {
      throw BreakException();
    } else if (node is ContinueStatement) {
      throw ContinueException();
    } else if (node is ThrowStatement) {
      final value = node.value != null ? _evaluate(node.value!, env) : null;
      throw ThrowException(value);
    } else if (node is TryCatchStatement) {
      _executeTryCatch(node, env);
    } else if (node is Block) {
      final blockEnv = Environment(env);
      _executeBlock(node.statements, blockEnv);
    } else if (node is ExpressionStatement) {
      _evaluate(node.expression, env);
    }
  }

  void _executeTryCatch(TryCatchStatement node, Environment env) {
    try {
      final tryEnv = Environment(env);
      _executeBlock(node.tryBlock, tryEnv);
    } on ThrowException catch (e) {
      if (node.catchBlock != null) {
        final catchEnv = Environment(env);
        if (node.catchVar != null) {
          catchEnv.define(node.catchVar!, e.value);
        }
        _executeBlock(node.catchBlock!, catchEnv);
      }
    } finally {
      if (node.finallyBlock != null) {
        _executeBlock(node.finallyBlock!, env);
      }
    }
  }

  dynamic _evaluate(AstNode node, Environment env) {
    if (node is NumberLiteral) return node.value;
    if (node is StringLiteral) return node.value;
    if (node is BooleanLiteral) return node.value;
    if (node is NullLiteral) return null;
    if (node is Identifier) return env.get(node.name);

    if (node is InterpolatedString) {
      final buffer = StringBuffer();
      for (final part in node.parts) {
        final value = _evaluate(part, env);
        buffer.write(value == null ? 'null' : _displayValue(value));
      }
      return buffer.toString();
    }

    if (node is TernaryExpression) {
      final condition = _evaluate(node.condition, env);
      return _isTruthy(condition) ? _evaluate(node.trueBranch, env) : _evaluate(node.falseBranch, env);
    }

    if (node is Assignment) {
      final value = _evaluate(node.value, env);
      env.set(node.name, value);
      return value;
    }

    if (node is ObjectLiteral) {
      final obj = <String, dynamic>{};
      for (final entry in node.properties.entries) {
        obj[entry.key] = _evaluate(entry.value, env);
      }
      return obj;
    }

    if (node is ArrayLiteral) {
      return node.elements.map((e) => _evaluate(e, env)).toList();
    }

    if (node is PropertyAccess) {
      final obj = _evaluate(node.object, env);
      dynamic propKey;
      if (node.isBracket) {
        propKey = _evaluate(node.property, env);
      } else {
        propKey = (node.property as Identifier).name;
      }

      if (obj is List) {
        if (propKey == 'length') return obj.length;
        if (propKey == 'push') {
          return (List<dynamic> args) {
            for (final arg in args) {
              obj.add(arg);
            }
            return obj.length;
          };
        }
        if (propKey == 'pop') {
          return (List<dynamic> args) => obj.isEmpty ? null : obj.removeLast();
        }
        if (propKey == 'shift') {
          return (List<dynamic> args) => obj.isEmpty ? null : obj.removeAt(0);
        }
        if (propKey == 'unshift') {
          return (List<dynamic> args) {
            for (var i = args.length - 1; i >= 0; i--) {
              obj.insert(0, args[i]);
            }
            return obj.length;
          };
        }
        if (propKey == 'includes') {
          return (List<dynamic> args) => obj.contains(args.first);
        }
        if (propKey == 'indexOf') {
          return (List<dynamic> args) => obj.indexOf(args.first);
        }
        if (propKey == 'join') {
          return (List<dynamic> args) => obj.map((e) => _displayValue(e)).join(args.isEmpty ? ',' : args.first.toString());
        }
        if (propKey == 'slice') {
          return (List<dynamic> args) {
            final start = args.isEmpty ? 0 : (args[0] as num).toInt();
            final end = args.length > 1 ? (args[1] as num).toInt() : obj.length;
            return obj.sublist(start < 0 ? 0 : start, end > obj.length ? obj.length : end).toList();
          };
        }
        if (propKey == 'splice') {
          return (List<dynamic> args) {
            final start = (args[0] as num).toInt();
            final deleteCount = args.length > 1 ? (args[1] as num).toInt() : obj.length - start;
            final removed = obj.sublist(start, (start + deleteCount).clamp(0, obj.length)).toList();
            final insertItems = args.length > 2 ? args.sublist(2) : const <dynamic>[];
            obj.removeRange(start, (start + deleteCount).clamp(0, obj.length));
            if (insertItems.isNotEmpty) {
              obj.insertAll(start, insertItems);
            }
            return removed;
          };
        }
        if (propKey is num) return obj[propKey.toInt()];
        return obj[(propKey as num).toInt()];
      } else if (obj is Map) {
        if (propKey == 'keys') {
          return (List<dynamic> args) => obj.keys.toList();
        }
        if (propKey == 'values') {
          return (List<dynamic> args) => obj.values.toList();
        }
        if (propKey == 'entries') {
          return (List<dynamic> args) => obj.entries.map((e) => [e.key.toString(), e.value]).toList();
        }
        if (propKey == 'hasProperty') {
          return (List<dynamic> args) => obj.containsKey(args.first.toString());
        }
        if (propKey == 'get') {
          return (List<dynamic> args) => obj[args.first.toString()];
        }
        if (propKey == 'set') {
          return (List<dynamic> args) {
            obj[args[0].toString()] = args[1];
            return obj;
          };
        }
        if (propKey == 'delete') {
          return (List<dynamic> args) {
            final removed = obj.remove(args.first.toString());
            return removed != null;
          };
        }
        return obj[propKey.toString()];
      } else if (obj is String) {
        if (propKey == 'length') return obj.length;
        if (propKey == 'trim') return (List<dynamic> args) => obj.trim();
        if (propKey == 'toUpperCase') return (List<dynamic> args) => obj.toUpperCase();
        if (propKey == 'toLowerCase') return (List<dynamic> args) => obj.toLowerCase();
        if (propKey == 'contains') return (List<dynamic> args) => obj.contains(args.first.toString());
        if (propKey == 'startsWith') return (List<dynamic> args) => obj.startsWith(args.first.toString());
        if (propKey == 'endsWith') return (List<dynamic> args) => obj.endsWith(args.first.toString());
        if (propKey == 'indexOf') return (List<dynamic> args) => obj.indexOf(args.first.toString());
        if (propKey == 'replace') return (List<dynamic> args) => obj.replaceAll(args[0].toString(), args[1].toString());
        if (propKey == 'split') return (List<dynamic> args) => obj.split(args.first.toString()).toList();
        if (propKey == 'substring')
          return (List<dynamic> args) {
            if (args.isEmpty) return obj;
            final start = (args[0] as num).toInt();
            if (args.length == 1) return obj.substring(start);
            final end = (args[1] as num).toInt();
            return obj.substring(start, end > obj.length ? obj.length : end);
          };
        if (propKey == 'charAt')
          return (List<dynamic> args) {
            final idx = (args[0] as num).toInt();
            if (idx < 0 || idx >= obj.length) return '';
            return obj.substring(idx, idx + 1);
          };
        if (propKey == 'padStart')
          return (List<dynamic> args) {
            final targetLength = (args[0] as num).toInt();
            final padString = args.length > 1 ? args[1].toString() : ' ';
            if (targetLength <= obj.length) return obj;
            var result = obj;
            var pad = padString.isEmpty ? ' ' : padString;
            while (result.length < targetLength) {
              result = pad + result;
              if (pad.length > 1) {
                final repeated = (targetLength - result.length).clamp(0, pad.length);
                if (repeated <= 0) break;
                result = pad.substring(0, repeated) + result.substring(repeated);
              }
            }
            if (result.length > targetLength) {
              result = result.substring(result.length - targetLength);
            }
            return result;
          };
        if (propKey == 'padEnd')
          return (List<dynamic> args) {
            final targetLength = (args[0] as num).toInt();
            final padString = args.length > 1 ? args[1].toString() : ' ';
            if (targetLength <= obj.length) return obj;
            var pad = padString.isEmpty ? ' ' : padString;
            var result = obj;
            while (result.length < targetLength) {
              result = result + pad;
              if (pad.length > 1) {
                final repeated = (targetLength - result.length).clamp(0, pad.length);
                if (repeated <= 0) break;
                result = result.substring(0, result.length - repeated) + pad.substring(0, repeated);
              }
            }
            if (result.length > targetLength) {
              result = result.substring(0, targetLength);
            }
            return result;
          };
        if (propKey == 'repeat')
          return (List<dynamic> args) {
            final count = (args[0] as num).toInt();
            if (count <= 0) return '';
            final buffer = StringBuffer();
            for (var i = 0; i < count; i++) {
              buffer.write(obj);
            }
            return buffer.toString();
          };
        if (propKey == 'substr')
          return (List<dynamic> args) {
            final start = (args[0] as num).toInt();
            final len = args.length > 1 ? (args[1] as num).toInt() : obj.length - start;
            final end = start + len;
            return obj.substring(start, end > obj.length ? obj.length : end);
          };
        throw Exception('String has no property "$propKey". Use method call: str.$propKey()');
      }
      throw Exception('Cannot access property on ${obj.runtimeType}');
    }

    if (node is BinaryExpression) {
      final left = _evaluate(node.left, env);
      if (node.operator == '&&') return _isTruthy(left) && _isTruthy(_evaluate(node.right, env));
      if (node.operator == '||') return _isTruthy(left) || _isTruthy(_evaluate(node.right, env));

      final right = _evaluate(node.right, env);

      switch (node.operator) {
        case '+':
          if (left is String || right is String) return '$left$right';
          return (left as num) + (right as num);
        case '-':
          return (left as num) - (right as num);
        case '*':
          return (left as num) * (right as num);
        case '/':
          return (left as num) / (right as num);
        case '%':
          return (left as num) % (right as num);
        case '==':
          return left == right;
        case '!=':
          return left != right;
        case '<':
          return (left as num) < (right as num);
        case '>':
          return (left as num) > (right as num);
        case '<=':
          return (left as num) <= (right as num);
        case '>=':
          return (left as num) >= (right as num);
        default:
          throw Exception('Unsupported operator: ${node.operator}');
      }
    }

    if (node is UnaryExpression) {
      final operand = _evaluate(node.operand, env);
      if (node.operator == '-') return -(operand as num);
      if (node.operator == '!') return !_isTruthy(operand);
      if (node.operator == '++') {
        if (node.operand is Identifier) {
          final name = (node.operand as Identifier).name;
          final newValue = (env.get(name) as num) + 1;
          env.set(name, newValue);
          return newValue;
        }
      }
      if (node.operator == '--') {
        if (node.operand is Identifier) {
          final name = (node.operand as Identifier).name;
          final newValue = (env.get(name) as num) - 1;
          env.set(name, newValue);
          return newValue;
        }
      }
      if (node.operator == 'postfix++') {
        if (node.operand is Identifier) {
          final name = (node.operand as Identifier).name;
          final oldValue = env.get(name) as num;
          final newValue = oldValue + 1;
          env.set(name, newValue);
          return oldValue;
        }
      }
      if (node.operator == 'postfix--') {
        if (node.operand is Identifier) {
          final name = (node.operand as Identifier).name;
          final oldValue = env.get(name) as num;
          final newValue = oldValue - 1;
          env.set(name, newValue);
          return oldValue;
        }
      }
    }

    if (node is FunctionCall) {
      final callee = node.callee;
      final args = node.arguments.map((a) => _evaluate(a, env)).toList();

      if (callee is PropertyAccess) {
        final obj = _evaluate(callee.object, env);
        final propertyName = callee.isBracket ? _evaluate(callee.property, env).toString() : (callee.property as Identifier).name;
        if (obj is List && propertyName == 'length' && args.isEmpty) {
          return obj.length;
        }
        if (obj is String && propertyName == 'length' && args.isEmpty) {
          return obj.length;
        }
      }

      dynamic funcCallee;
      try {
        funcCallee = _evaluate(callee, env);
      } catch (e) {
        if (_onCommand != null && callee is Identifier) {
          final params = <String, dynamic>{};
          for (var i = 0; i < node.arguments.length; i++) {
            params['${i + 1}'] = _evaluate(node.arguments[i], env);
          }
          final result = _onCommand!(callee.name, params);
          if (result.handled) return result.value;
        }
        rethrow;
      }

      if (funcCallee is Map && funcCallee['type'] == 'function') {
        final funcDef = funcCallee['def'] as FunctionDefinition;
        final funcEnv = Environment(funcCallee['env'] as Environment);

        for (var i = 0; i < funcDef.parameters.length; i++) {
          funcEnv.define(funcDef.parameters[i], i < args.length ? args[i] : null);
        }

        try {
          _executeBlock(funcDef.body, funcEnv);
          return null;
        } on ReturnException catch (e) {
          return e.value;
        }
      }

      if (funcCallee is Function) {
        return Function.apply(funcCallee, [args]);
      }
    }

    if (node is FunctionDefinition) {
      return {'type': 'function', 'def': node, 'env': env};
    }

    throw Exception('Unknown node type: ${node.runtimeType}');
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return true;
  }

  String _displayValue(dynamic v) {
    if (v is num) return v.toString();
    if (v is Map) return _stringifyObject(v);
    return v.toString();
  }

  String _stringifyObject(Map obj) {
    final entries = obj.entries
        .map((e) {
          final val = e.value;
          if (val is String) return '${e.key}:"$val"';
          if (val is Map) return '${e.key}:${_stringifyObject(val)}';
          if (val is List) {
            final items = val.map((v) => v is String ? '"$v"' : _displayValue(v)).join(',');
            return '${e.key}:[$items]';
          }
          return '${e.key}:${_displayValue(val)}';
        })
        .join(',');
    return '{${entries}}';
  }

  dynamic _convertJsonValue(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        result[entry.key.toString()] = _convertJsonValue(entry.value);
      }
      return result;
    }
    if (value is List) {
      return value.map(_convertJsonValue).toList();
    }
    return value;
  }
}
