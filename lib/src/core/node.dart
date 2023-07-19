import 'package:petitparser/petitparser.dart';

class Loc {
  Loc(this.start, this.end);
  Loc.fromToken(Token token)
    : start = token.start,
      end = token.stop - 1;

  final int start;
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

typedef Visitor = Node Function(Node);

abstract class Node {
  Node([this.loc]);

  String get type;
  Loc? loc;

  static const statementTypes = {'def', 'return', 'each', 'for', 'loop', 'break', 'continue', 'assign', 'addAssign', 'subAssign'};
  bool isStatement() => statementTypes.contains(type);

  static const exprTypes = {'if', 'fn', 'match', 'block', 'tmpl', 'str', 'num', 'bool', 'null', 'obj', 'arr', 'identifier', 'call', 'index', 'prop'};
  bool isExpression() => exprTypes.contains(type);

  Node visit(Visitor fn) {
    final result = fn(this);
    result.accept(fn);
    return result;
  }

  void accept(Visitor fn) {}
}

mixin NameProp on Node {
  String get name;
}

mixin OptionalNameProp on Node {
  String? get name;
}