import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
    function add(a, b) {
      return a + b;
    }

    function greet(name) {
      return 'Hello, ' + name + '!';
    }

    function computePrice(base, tax) {
      return add(base, base * tax);
    }

    print('sum:', add(10, 20));
    print(greet('Alice'));
    print('total:', computePrice(100, 0.2));
  ''';

  runScript(source);
}
