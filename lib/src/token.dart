enum TokenType {
  number,
  string,
  identifier,

  function,
  varKeyword,
  returnKeyword,
  ifKeyword,
  elseKeyword,
  whileKeyword,
  forKeyword,
  trueKeyword,
  falseKeyword,
  nullKeyword,
  tryKeyword,
  catchKeyword,
  finallyKeyword,
  throwKeyword,
  breakKeyword,
  continueKeyword,

  plus,
  minus,
  star,
  slash,
  percent,
  plusPlus,
  minusMinus,
  equal,
  equalEqual,
  notEqual,
  less,
  greater,
  lessEqual,
  greaterEqual,
  and,
  or,
  not,

  assign,
  question,

  leftParen,
  rightParen,
  leftBrace,
  rightBrace,
  leftBracket,
  rightBracket,
  comma,
  semicolon,
  colon,
  dot,

  stringStart,
  stringPart,
  stringEnd,
  dollar,

  eof,
}

class Token {
  final TokenType type;
  final dynamic value;
  final int line;

  Token(this.type, this.value, this.line);

  @override
  String toString() => 'Token($type, $value, line:$line)';
}
