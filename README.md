# dartjs

A tiny JavaScript-like scripting runtime for Dart.

- Pure Dart
- JS-style objects, arrays, and strings
- CLI and package API
- Built-in HTTP helpers
- Works with Dart variables and callbacks

## Install

```yaml
dependencies:
  dartjs: ^0.1.0
```

## Quick start

### Run from Dart

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  runScript('''
    var user = { name: 'Alice', city: 'Moscow' };
    print('Hello, ' + user.name + '!');
  ''');
}
```

### Pass variables

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  runScript(
    '''
      print(user.name);
      print(gps.lat);
    ''',
    variables: {
      'user': {'name': 'Alice'},
      'gps': {'lat': 55.75},
    },
  );
}
```

### Shared context between scripts

You can run multiple scripts that share the same variables using `DartJSContext`.

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  final ctx = DartJSContext({'counter': 0});

  runScript('counter = counter + 1; print(counter);', context: ctx);
  runScript('counter = counter + 5; print(counter);', context: ctx);

  print('Final counter: ${ctx.get('counter')}');
}
```

### Extend with your own Dart functions

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  runScript(
    '''
      var id = getUserId();
      print('User id:', id);
    ''',
    onUnknownFunction: (String name, Map<String, dynamic> args) {
      if (name == 'getUserId') {
        return NativeFunctionReturn.ok('u-42');
      }
      return NativeFunctionReturn.skip();
    },
  );
}
```

This is the easiest way to expose Dart logic to the scripting layer without extra wiring.

A typical pattern for a small DSL is to register a few Dart functions and pass parameters directly from the script:

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  runScript(
    '''
      var id = getUserId();
      var total = add(10, 5);
      var label = formatUser('Alice', 30);
      print(id, total, label);
      setTAppTitle('DartJS);
    ''',
    onUnknownFunction: (String name, Map<String, dynamic> args) {
      switch (name) {
        case 'setTAppTitle'://set page title
          //setState((){
          //  title: args['arg0'] ?? ''; 
          //});   
          return NativeFunctionReturn.ok(true);
        case 'getUserId':
          return NativeFunctionReturn.ok('u-42');
        case 'add':
          final a = args['arg0'] ?? 0;
          final b = args['arg1'] ?? 0;
          return NativeFunctionReturn.ok(a + b);
        case 'formatUser':
          final name = args['arg0'] ?? 'Unknown';
          final age = args['arg1'] ?? 0;
          return NativeFunctionReturn.ok('$name ($age)');
        default:
          return NativeFunctionReturn.skip();
      }
    },
  );
}
```

### CLI

```bash
dart run dartjs script.mn
```

## Examples

### Strings and interpolation

```js
var name = 'Alice';
print('Hello, ${name}!');
print('  hello  '.trim().toUpperCase());
print('dart'.repeat(3));
```

### Arrays and objects

```js
var items = [1, 2, 3];
items.push(4);
print(items.join('-'));

var user = { name: 'Ivan', age: 25 };
print(user.name);
print(user.keys());
```

### Functions and callbacks

```js
function add(a, b) {
  return a + b;
}

print(add(2, 3));

setTimeOut(function() {
  print('done');
}, 100);
```

### HTTP

```js
http.getJson(
  'https://jsonplaceholder.typicode.com/todos/1',
  {},
  {},
  function(data) {
    print(data);
  },
  function(error, code) {
    print('error:', error, code);
  }
);
```

## Why dartjs?

Because you can write lightweight scripting logic in a JavaScript-like syntax while still running inside a Dart application.

## License

MIT
