# dartjs

Pure Dart interpreter for a JavaScript-like scripting language.

## Install

Add to your project:

```yaml
dependencies:
  dartjs: ^0.1.0
```

Or run directly from the package folder:

```bash
dart run dartjs <script.mn>
```

## Quick start

### Runtime API

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
    var user = { name: 'Alice', city: 'Moscow' };
    print('Hello, ' + user.name + '!');
  ''';

  runScript(source);
}
```

### With variables

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  final interpreter = runScript(
    '''
      var currentUser = user;
      var lat = gps.lat;
      print(currentUser.name);
      print(lat);
    ''',
    variables: {
      'user': {'name': 'Alice'},
      'gps': {'lat': 55.75, 'lng': 37.62},
    },
  );

  print(interpreter.getGlobal('lat'));
}
```

### With unknown function handler

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  runScript(
    '''
      var userId = getUserId();
      print(userId);
    ''',
    onUnknownFunction: (String name, Map<String, dynamic> params) {
      if (name == 'getUserId') {
        return NativeFunctionReturn.ok('u-42');
      }
      return NativeFunctionReturn.skip();
    },
  );
}
```

### Shared context across multiple scripts

If you need an init section and separate event scripts that reuse the same variables, use `DartJSContext`:

```dart
import 'package:dartjs/dartjs.dart';

void main() {
  final ctx = DartJSContext({'counter': 0, 'user': {'name': 'Alice'}});

  final init = """
    // init script
    counter = counter + 1;
  """;

  runScript(init, context: ctx);

  final onClick = """
    // event script
    counter = counter + 5;
    print('user: ' + user.name);
  """;

  runScript(onClick, context: ctx);
  print('Final counter: ${ctx.get('counter')}');
}
```

## CLI

```bash
dart run dartjs hellow-world.mn
```

The CLI reads a `.mn` file and executes it.

## Values and literals

```js
var num = 42;
var text = 'hello';
var flag = true;
var nothing = null;
var items = [1, 2, 3];
var user = { name: 'Alice', age: 30 };
```

## Variables

```js
var x = 10;
var name = 'World';

x = 20;
```

## Strings

```js
var s = 'hello world';

print(s.length);
print(s.toUpperCase());
print(s.toLowerCase());
print(s.trim());
print(s.contains('world'));
print(s.startsWith('hello'));
print(s.endsWith('world'));
print(s.indexOf('world'));
print(s.replace('world', 'Mongol'));
print(s.substring(0, 5));
print(s.charAt(1));
print(s.split(' '));
print('  hi  '.trim().toUpperCase());
print('42'.padStart(6, '0'));
print('hi'.padEnd(6, '.'));
print('ab'.repeat(3));
```

Interpolation works with `${...}`:

```js
var user = { name: 'Alice', city: 'Moscow' };
var msg = 'User ${user.name} from ${user.city}';
print(msg);
```

## Arrays

```js
var arr = [1, 2, 3];
arr.push(4);
arr.pop();
arr.unshift(0);
print(arr);          // [0, 1, 2, 3]
print(arr.length);   // 4
print(arr.join('-'));
print(arr.slice(1, 3));
print(arr.indexOf(2));
print(arr.includes(3));
```

## Objects / maps

```js
var user = {
  name: 'Alice',
  age: 30,
  city: 'Paris'
};

print(user.name);
print(user['name']);
print(user.keys());
print(user.values());
print(user.hasProperty('city'));
user.set('role', 'admin');
print(user.get('role'));
```

## Operators

```js
1 + 2
3 - 1
2 * 4
8 / 2
10 % 3

x == y
x != y
x < y
x > y
x <= y
x >= y

flag && other
flag || other
!flag
```

## Conditionals

```js
if (x > 10) {
  print('bigger');
} else if (x > 5) {
  print('medium');
} else {
  print('small');
}
```

## Loops

```js
var total = 0;
for (var i = 0; i < 5; i++) {
  total = total + i;
}
print(total);

var i = 0;
while (i < 5) {
  print(i);
  i++;
}
```

## Functions

```js
function add(a, b) {
  return a + b;
}

print(add(2, 3));

var double = function(x) {
  return x * 2;
};

print(double(5));
```

## Callback style

```js
setTimeOut(function() {
  print('done after 1000 ms');
}, 1000);
```

## JSON

```js
var data = json('{"id":10,"name":"Ivan"}');
print(data.name);

var arr = ['a', 'b'];
print(jsonEncode(arr));
```

## HTTP

The runtime exposes a global `http` object.

### GET JSON

```js
http.getJson(
  'https://jsonplaceholder.typicode.com/todos/1',
  {userId: 1},
  {Authorization: 'Bearer demo-token'},
  function(data) {
    print('GET success:', data);
  },
  function(error, code) {
    print('GET error:', error, code);
  }
);
```

### POST JSON

```js
http.postJson(
  'https://api.example.com/items',
  {type: 'demo'},
  {Authorization: 'Bearer demo-token'},
  function(data) {
    print('POST success:', data);
  },
  function(error, code) {
    print('POST error:', error, code);
  }
);
```

### Simplified request form

```js
http.get('https://api.example.com/items');
http.post('https://api.example.com/items', {hello: 'world'});
```

## Builtins

```js
print(value)
random(min, max)
parseInt('42')
length(value)
split(separator, text)
substr(start, length, text)
trim(text)
toUpperCase(text)
toLowerCase(text)
contains(text, needle)
replace(text, old, new)

PI
E
SQRT2
```

## Error handling

```js
try {
  var data = json('{"bad":');
} catch (e) {
  print('Error:', e);
}
```

## Comments

```js
// single line comment
/* multi-line comment */
```

## Example full script

```js
var user = {
  name: 'Ivan',
  age: 25,
  skills: ['dart', 'js', 'python']
};

print('User: ${user.name}, age: ${user.age}');
print('Skills:', user.skills.join(', '));

var long = user.skills.filter(function(s) {
  return length(s) > 2;
});
print('Long skills:', long.join(', '));

http.getJson(
  'https://jsonplaceholder.typicode.com/todos/1',
  {},
  {},
  function(data) {
    print('Response:', data);
  },
  function(error, code) {
    print('Error:', error, code);
  }
);
```

## License

MIT
