abstract class AstNode {}

class NumberLiteral extends AstNode {
  final num value;
  NumberLiteral(this.value);
}

class StringLiteral extends AstNode {
  final String value;
  StringLiteral(this.value);
}

class BooleanLiteral extends AstNode {
  final bool value;
  BooleanLiteral(this.value);
}

class NullLiteral extends AstNode {}

class Identifier extends AstNode {
  final String name;
  Identifier(this.name);
}

class BinaryExpression extends AstNode {
  final AstNode left;
  final String operator;
  final AstNode right;
  BinaryExpression(this.left, this.operator, this.right);
}

class UnaryExpression extends AstNode {
  final String operator;
  final AstNode operand;
  UnaryExpression(this.operator, this.operand);
}

class Assignment extends AstNode {
  final String name;
  final AstNode value;
  Assignment(this.name, this.value);
}

class FunctionCall extends AstNode {
  final AstNode callee;
  final List<AstNode> arguments;
  FunctionCall(this.callee, this.arguments);
}

class FunctionDefinition extends AstNode {
  final String? name;
  final List<String> parameters;
  final List<AstNode> body;
  FunctionDefinition(this.name, this.parameters, this.body);
}

class VarDeclaration extends AstNode {
  final String name;
  final AstNode? initializer;
  VarDeclaration(this.name, this.initializer);
}

class ReturnStatement extends AstNode {
  final AstNode? value;
  ReturnStatement(this.value);
}

class IfStatement extends AstNode {
  final AstNode condition;
  final List<AstNode> thenBranch;
  final List<AstNode>? elseBranch;
  IfStatement(this.condition, this.thenBranch, this.elseBranch);
}

class WhileStatement extends AstNode {
  final AstNode condition;
  final List<AstNode> body;
  WhileStatement(this.condition, this.body);
}

class ForStatement extends AstNode {
  final AstNode? initializer;
  final AstNode? condition;
  final AstNode? update;
  final List<AstNode> body;
  ForStatement(this.initializer, this.condition, this.update, this.body);
}

class ExpressionStatement extends AstNode {
  final AstNode expression;
  ExpressionStatement(this.expression);
}

class Block extends AstNode {
  final List<AstNode> statements;
  Block(this.statements);
}

class ObjectLiteral extends AstNode {
  final Map<String, AstNode> properties;
  ObjectLiteral(this.properties);
}

class ArrayLiteral extends AstNode {
  final List<AstNode> elements;
  ArrayLiteral(this.elements);
}

class PropertyAccess extends AstNode {
  final AstNode object;
  final AstNode property;
  final bool isBracket;
  PropertyAccess(this.object, this.property, {this.isBracket = false});
}

class PropertyAssignment extends AstNode {
  final PropertyAccess target;
  final AstNode value;
  PropertyAssignment(this.target, this.value);
}

class InterpolatedString extends AstNode {
  final List<AstNode> parts;
  InterpolatedString(this.parts);
}

class TernaryExpression extends AstNode {
  final AstNode condition;
  final AstNode trueBranch;
  final AstNode falseBranch;
  TernaryExpression(this.condition, this.trueBranch, this.falseBranch);
}

class TryCatchStatement extends AstNode {
  final List<AstNode> tryBlock;
  final String? catchVar;
  final List<AstNode>? catchBlock;
  final List<AstNode>? finallyBlock;
  TryCatchStatement(this.tryBlock, this.catchVar, this.catchBlock, this.finallyBlock);
}

class ThrowStatement extends AstNode {
  final AstNode? value;
  ThrowStatement(this.value);
}

class BreakStatement extends AstNode {}

class ContinueStatement extends AstNode {}
