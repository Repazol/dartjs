import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
    var user = {
      name: 'Alice',
      age: 30,
      city: 'Paris'
    };

    print('keys:', user.keys());
    print('hasProperty:', user.hasProperty('city'));
    print('name:', user.name);
    print('age:', user.age);

    user.set('role', 'admin');
    print('role:', user.get('role'));

    var users = [
      { name: 'Alice', age: 30 },
      { name: 'Bob', age: 28 }
    ];

    print('first user:', users[0].name);
  ''';

  runScript(source);
}
