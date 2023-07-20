import 'package:petitparser/petitparser.dart';

/// The location of a node.
class Loc {
  /// Creates a new Loc.
  Loc(this.start, this.end);
  /// Creates a new Loc from a Token.
  Loc.fromToken(Token token)
    : start = token.start,
      end = token.stop - 1;

  /// Where this node starts in the script.
  final int start;
  /// Where this node ends in the script.
  final int end;

  @override
  String toString() => 'start: $start, end: $end';

  @override
  bool operator ==(Object? other) => other is Loc &&
      other.start == start &&
      other.end == end;
  
  @override
  int get hashCode => Object.hash(runtimeType, start, end);
}

/// A visitor function.
typedef Visitor = Node Function(Node);

/// An AiScript node.
abstract class Node {
  Node([this.loc]);

  /// The type of the node.
  String get type;
  /// The location of the source string that created this node.
  Loc? loc;

  static const statementTypes = {'def', 'return', 'each', 'for', 'loop', 'break', 'continue', 'assign', 'addAssign', 'subAssign'};
  /// Checks if the node is a statement.
  bool isStatement() => statementTypes.contains(type);

  static const exprTypes = {'if', 'fn', 'match', 'block', 'tmpl', 'str', 'num', 'bool', 'null', 'obj', 'arr', 'identifier', 'call', 'index', 'prop'};
  /// Checks if the node is an expression.
  bool isExpression() => exprTypes.contains(type);

  /// Visits the node and its child nodes.
  Node visit(Visitor fn) {
    final result = fn(this);
    result.accept(fn);
    return result;
  }

  /// Accepts a visitor.
  void accept(Visitor fn) {}
}

mixin NameProp on Node {
  /// The name of the node.
  String get name;
}

mixin OptionalNameProp on Node {
  /// The name of the node.
  String? get name;
}