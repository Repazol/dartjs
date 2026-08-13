import 'package:dartjs/dartjs.dart';

void main() {
  final ctx = DartJSContext({
    'counter': 0,
    'user': {'name': 'Alice'},
  });

  final initScript = r'''
    // init script: prepare shared state
    counter = counter + 1;
    print('init counter=' + counter);
  ''';

  runScript(initScript, context: ctx);

  final clickScript = r'''
    // event script: re-use same context
    counter = counter + 5;
    print('onClick counter=' + counter);
    print('user: ' + user.name);
  ''';

  runScript(clickScript, context: ctx);

  print('Final counter from Dart: ${ctx.get('counter')}');
}
