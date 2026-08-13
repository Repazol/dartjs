import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
    var user = { name: 'Alice', city: 'Moscow' };
    var greeting = 'Hello, \${user.name}!';

    print(greeting);
    print('City:', user.city);
    print('Length:', user.name.length);
  ''';

  runScript(source);
}
