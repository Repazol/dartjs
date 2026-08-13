import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
    var total = 0;
    var items = [5, 10, 15, 20];

    for (var i = 0; i < items.length; i++) {
      total = total + items[i];
    }

    var doubled = [];
    for (var i = 0; i < 5; i++) {
      doubled.push(i * 2);
    }

    print('sum:', total);
    print('doubled:', doubled);
  ''';

  runScript(source);
}
