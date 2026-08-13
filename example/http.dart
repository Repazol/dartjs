import 'package:dartjs/dartjs.dart';

void main() {
  final source = '''
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
  ''';

  runScript(source);
}
