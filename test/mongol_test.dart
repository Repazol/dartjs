import 'dart:convert';
import 'dart:io';

import 'package:dartjs/dartjs.dart';
import 'package:test/test.dart';

void main() {
  test('Lexer and interpreter can evaluate a simple expression', () {
    final tokens = Lexer('var x = 2 + 3; print(x);').tokenize();
    final ast = Parser(tokens).parse();
    final interpreter = Interpreter();

    interpreter.run(ast);

    expect(interpreter, isA<Interpreter>());
  });

  test('runScript accepts context variables and unknown function callback', () {
    final interpreter = runScript(
      '''
        var currentUser = user;
        var coords = gps;
        var userId = getUserId();
      ''',
      variables: {
        'user': {'name': 'Alice'},
        'gps': {'lat': 55.75, 'lng': 37.62},
      },
      onUnknownFunction: (String name, Map<String, dynamic> args) {
        if (name == 'getUserId') {
          return NativeFunctionReturn.ok('u-42');
        }
        return NativeFunctionReturn.skip();
      },
    );

    expect(interpreter.getGlobal('currentUser')['name'], equals('Alice'));
    expect(interpreter.getGlobal('coords')['lat'], equals(55.75));
    expect(interpreter.getGlobal('userId'), equals('u-42'));
  });

  test('for-loop update supports ++', () {
    final interpreter = Interpreter();
    final ast = Parser(
      Lexer('''
      var total = 0;
      for (var i = 0; i < 3; i++) {
        total = total + i;
      }
    ''').tokenize(),
    ).parse();

    interpreter.run(ast);

    expect(interpreter.getGlobal('total'), equals(3));
  });

  test('anonymous functions can be used as expressions', () {
    final interpreter = Interpreter();
    final ast = Parser(
      Lexer('''
      var fn = function(a) {
        return a + 1;
      };
      var value = fn(2);
    ''').tokenize(),
    ).parse();

    interpreter.run(ast);

    expect(interpreter.getGlobal('value'), equals(3));
  });

  test('map and list methods can be called', () {
    final interpreter = Interpreter();
    final ast = Parser(
      Lexer('''
      var store = { id: 10, name: 'Alice' };
      var keys = store.keys();
      var hasName = store.hasProperty('name');
      var values = [];
      values.push(42);
      values.push(7);
      var has42 = values.includes(42);
      var idx = values.indexOf(7);
      var joined = values.join('-');
      var popped = values.pop();
      var first = [10, 20, 30].slice(1, 3);
      var mapEntries = store.entries();
      var objValue = store.get('name');
      var removed = store.delete('id');
    ''').tokenize(),
    ).parse();

    interpreter.run(ast);

    expect(interpreter.getGlobal('keys'), equals(['id', 'name']));
    expect(interpreter.getGlobal('hasName'), isTrue);
    expect(interpreter.getGlobal('values'), equals([42]));
    expect(interpreter.getGlobal('has42'), isTrue);
    expect(interpreter.getGlobal('idx'), equals(1));
    expect(interpreter.getGlobal('joined'), equals('42-7'));
    expect(interpreter.getGlobal('popped'), equals(7));
    expect(interpreter.getGlobal('first'), equals([20, 30]));
    expect(interpreter.getGlobal('mapEntries'), isA<List>());
    expect(interpreter.getGlobal('objValue'), equals('Alice'));
    expect(interpreter.getGlobal('removed'), isTrue);
  });

  test('http object exposes request methods and headers support', () {
    final interpreter = Interpreter();
    final http = interpreter.getGlobal('http') as Map<String, dynamic>;

    expect(http['get'], isA<Function>());
    expect(http['post'], isA<Function>());
    expect(http['getJson'], isA<Function>());
    expect(http['postJson'], isA<Function>());
  });

  test('http.getJson can accept query, headers, and callback handlers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    server.listen((request) {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode([
          {'id': 1, 'name': 'Alice'},
        ]),
      );
      request.response.close();
    }, cancelOnError: true);

    addTearDown(() async {
      await server.close(force: true);
    });

    final script =
        '''
      var response = null;
      http.getJson(
        'http://localhost:$port/items',
        {id: '10'},
        {Authorization: 'Bearer token'},
        function(data) {
          response = data;
          return data;
        },
        function(error, code) {
          response = error;
          return error;
        }
      );
    ''';

    final interpreter = Interpreter();
    final ast = Parser(Lexer(script).tokenize()).parse();
    interpreter.run(ast);
    await interpreter.waitForPendingAsyncTasks();

    expect(interpreter.getGlobal('response'), isA<List>());
    expect(interpreter.getGlobal('response')[0]['name'], equals('Alice'));
  });

  test('interpolated strings parse and evaluate', () {
    final interpreter = Interpreter();
    final ast = Parser(
      Lexer('''
      var user = { name: 'Alice' };
      var msg = 'Hello \${user.name}!';
    ''').tokenize(),
    ).parse();

    interpreter.run(ast);

    expect(interpreter.getGlobal('msg'), equals('Hello Alice!'));
  });

  test('string methods behave like JS object methods', () {
    final interpreter = Interpreter();
    final ast = Parser(
      Lexer('''
      var text = 'Hello, DartJS!';
      var upper = text.toUpperCase();
      var lower = text.toLowerCase();
      var trimmed = '   hello world   '.trim();
      var contains = text.contains('DartJS');
      var replaced = text.replace('DartJS', 'World');
      var split = 'id,name,email'.split(',');
      var sub = text.substr(7, 5);
      var length = text.length;
      var starts = text.startsWith('Hello');
      var ends = text.endsWith('!');
      var idx = text.indexOf('Dart');
      var char = text.charAt(1);
      var paddedLeft = '42'.padStart(6, '0');
      var paddedRight = 'hi'.padEnd(6, '.');
      var repeated = 'ab'.repeat(3);
      var missing = text.indexOf('xyz');
    ''').tokenize(),
    ).parse();

    interpreter.run(ast);

    expect(interpreter.getGlobal('upper'), equals('HELLO, DARTJS!'));
    expect(interpreter.getGlobal('lower'), equals('hello, dartjs!'));
    expect(interpreter.getGlobal('trimmed'), equals('hello world'));
    expect(interpreter.getGlobal('contains'), isTrue);
    expect(interpreter.getGlobal('replaced'), equals('Hello, World!'));
    expect(interpreter.getGlobal('split'), equals(['id', 'name', 'email']));
    expect(interpreter.getGlobal('sub'), equals('DartJ'));
    expect(interpreter.getGlobal('length'), equals(14));
    expect(interpreter.getGlobal('starts'), isTrue);
    expect(interpreter.getGlobal('ends'), isTrue);
    expect(interpreter.getGlobal('idx'), equals(7));
    expect(interpreter.getGlobal('char'), equals('e'));
    expect(interpreter.getGlobal('paddedLeft'), equals('000042'));
    expect(interpreter.getGlobal('paddedRight'), equals('hi....'));
    expect(interpreter.getGlobal('repeated'), equals('ababab'));
    expect(interpreter.getGlobal('missing'), equals(-1));
  });
}
