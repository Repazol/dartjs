import 'package:dartjs/dartjs.dart';
import 'package:test/test.dart';

void main() {
  test('Lexer parses a simple statement', () {
    final tokens = Lexer('var x = 2 + 3;').tokenize();
    expect(tokens.isNotEmpty, isTrue);
    expect(tokens.first.type, equals(TokenType.varKeyword));
  });

  test('Interpreter runs a valid script', () {
    final tokens = Lexer('var x = 2 + 3;').tokenize();
    final ast = Parser(tokens).parse();
    final interpreter = Interpreter();
    expect(() => interpreter.run(ast), returnsNormally);
  });
}
