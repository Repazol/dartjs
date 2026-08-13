import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
    var text = 'Hello, DartJS!';

    print('length:', text.length);
    print('upper:', text.toUpperCase());
    print('lower:', text.toLowerCase());
    print('trim:', '   hello world   '.trim());
    print('contains:', text.contains('DartJS'));
    print('startsWith:', text.startsWith('Hello'));
    print('endsWith:', text.endsWith('!'));
    print('indexOf:', text.indexOf('Dart'));
    print('replace:', text.replace('DartJS', 'World'));
    print('substring:', text.substring(7, 12));
    print('charAt:', text.charAt(1));
    print('split:', 'id,name,email'.split(','));

    var user = { name: 'Alice', city: 'Moscow' };
    var msg = 'User \${user.name} from \${user.city}';
    print('interpolated:', msg);

    var sub = text.substr(7, 5);
    print('substr:', sub);

    print('padStart:', '42'.padStart(6, '0'));
    print('padEnd:', 'hi'.padEnd(6, '.'));
    print('repeat:', 'ab'.repeat(3));
  ''';

  runScript(source);
}
