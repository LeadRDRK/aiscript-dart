import 'node.dart';

class NamespaceNode extends Node with NameProp {
  NamespaceNode({required this.name, required this.members, Loc? loc}) : super(loc);

  @override
  String get type => 'ns';

  @override
  String name;
  List<Node> members; // (DefinitionNode | NamespaceNode)[]

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < members.length; ++i) {
      members[i] = members[i].visit(fn);
    }
  }
}

class MetaNode extends Node with OptionalNameProp {
  MetaNode({this.name, required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'meta';

  @override
  String? name;
  Node value; // Expression
}

class DefinitionNode extends Node with NameProp {
  DefinitionNode({required this.name, this.varType, required this.expr, required this.mut, required this.attr, Loc? loc}) : super(loc);

  @override
  String get type => 'def';

  @override
  String name;
  Node? varType; // NamedTypeSourceNode | FnTypeSourceNode
  Node expr; // Expression
  bool mut;
  List<AttributeNode> attr;

  @override
  void accept(Visitor fn) {
    expr = expr.visit(fn);
  }
}

class AttributeNode extends Node with NameProp {
  AttributeNode({required this.name, required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'attr';

  @override
  String name;
  Node value; // Expression
}

class ReturnNode extends Node {
  ReturnNode({required this.expr, Loc? loc}) : super(loc);

  @override
  String get type => 'return';

  Node expr; // Expression

  @override
  void accept(Visitor fn) {
    expr = expr.visit(fn);
  }
}

class EachNode extends Node {
  EachNode({required this.varName, required this.items, required this.body, Loc? loc}) : super(loc);

  @override
  String get type => 'each';

  String varName;
  Node items; // Expression
  Node body; // Statement | Expression

  @override
  void accept(Visitor fn) {
    items = items.visit(fn);
    body = body.visit(fn);
  }
}

class ForNode extends Node {
  ForNode({this.varName, this.from, this.to, this.times, required this.body, Loc? loc}) : super(loc);

  @override
  String get type => 'for';

  String? varName;
  Node? from; // Expression
  Node? to; // Expression
  Node? times; // Expression
  Node body; // Statement | Expression

  @override
  void accept(Visitor fn) {
    from = from?.visit(fn);
    to = to?.visit(fn);
    times = times?.visit(fn);
    body = body.visit(fn);
  }
}

class LoopNode extends Node {
  LoopNode({required this.statements, Loc? loc}) : super(loc);

  @override
  String get type => 'loop';

  List<Node> statements; // (Statement | Expression)[]

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < statements.length; ++i) {
      statements[i] = statements[i].visit(fn);
    }
  }
}

class BreakNode extends Node {
  BreakNode({Loc? loc}) : super(loc);

  @override
  String get type => 'break';
}

class ContinueNode extends Node {
  ContinueNode({Loc? loc}) : super(loc);

  @override
  String get type => 'continue';
}

abstract class BaseAssignNode extends Node {
  BaseAssignNode(this.dest, this.expr, Loc? loc) : super(loc);

  Node dest; // Expression
  Node expr; // Expression

  @override
  void accept(Visitor fn) {
    dest = dest.visit(fn);
    expr = expr.visit(fn);
  }
}

class AssignNode extends BaseAssignNode {
  AssignNode({required Node dest, required Node expr, Loc? loc}) : super(dest, expr, loc);

  @override
  String get type => 'assign';
}

class AddAssignNode extends BaseAssignNode {
  AddAssignNode({required Node dest, required Node expr, Loc? loc}) : super(dest, expr, loc);

  @override
  String get type => 'addAssign';
}

class SubAssignNode extends BaseAssignNode {
  SubAssignNode({required Node dest, required Node expr, Loc? loc}) : super(dest, expr, loc);

  @override
  String get type => 'subAssign';
}

class NotNode extends Node {
  NotNode({required this.expr, Loc? loc}) : super(loc);

  @override
  String get type => 'not';

  Node expr; // Expression

  @override
  void accept(Visitor fn) {
    expr = expr.visit(fn);
  }
}

class ElseifBlock {
  ElseifBlock(this.cond, this.then);

  Node cond; // Expression
  Node then; // Statement | Expression
}

class IfNode extends Node {
  IfNode({required this.cond, required this.then, required this.elseifBlocks, this.elseBlock, Loc? loc}) : super(loc);

  @override
  String get type => 'if';

  Node cond; // Expression
  Node then; // Statement | Expression
  List<ElseifBlock> elseifBlocks;
  Node? elseBlock; // Statement | Expression

  @override
  void accept(Visitor fn) {
    cond = cond.visit(fn);
    then = then.visit(fn);
    for (final prop in elseifBlocks) {
      prop.cond = prop.cond.visit(fn);
      prop.then = prop.then.visit(fn);
    }
    elseBlock = elseBlock?.visit(fn);
  }
}

class FnParam {
  FnParam(this.name, this.paramType);

  String name;
  Node? paramType; // NamedTypeSourceNode | FnTypeSourceNode
}

class FnNode extends Node {
  FnNode({required this.params, this.retType, required this.children, Loc? loc}) : super(loc);

  @override
  String get type => 'fn';

  List<FnParam> params;
  Node? retType; // NamedTypeSourceNode | FnTypeSourceNode
  List<Node> children; // (Statement | Expression)[]

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < children.length; ++i) {
      children[i] = children[i].visit(fn);
    }
  }
}

class MatchCase {
  MatchCase(this.q, this.a);

  Node q; // Expression
  Node a; // Statement | Expression
}

class MatchNode extends Node {
  MatchNode({required this.about, required this.qs, this.defaultRes, Loc? loc}) : super(loc);

  @override
  String get type => 'match';

  Node about; // Expression
  List<MatchCase> qs;
  Node? defaultRes;

  @override
  void accept(Visitor fn) {
    about = about.visit(fn);
    for (final prop in qs) {
      prop.q = prop.q.visit(fn);
      prop.a = prop.a.visit(fn);
    }
    defaultRes = defaultRes?.visit(fn);
  }
}

class BlockNode extends Node {
  BlockNode({required this.statements, Loc? loc}) : super(loc);

  @override
  String get type => 'block';

  List<Node> statements; // (Statement | Expression)[]

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < statements.length; ++i) {
      statements[i] = statements[i].visit(fn);
    }
  }
}

class TmplNode extends Node {
  TmplNode({required this.tmpl, Loc? loc}) : super(loc);

  @override
  String get type => 'tmpl';

  List<dynamic> tmpl; // (string | Expression)[]

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < tmpl.length; ++i) {
      final item = tmpl[i];
      if (item is Node) {
        tmpl[i] = item.visit(fn);
      }
    }
  }
}

class StrNode extends Node {
  StrNode({required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'str';

  String value;
}

class NumNode extends Node {
  NumNode({required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'num';

  num value;
}

class BoolNode extends Node {
  BoolNode({required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'bool';

  bool value;
}

class NullNode extends Node {
  NullNode({Loc? loc}) : super(loc);

  @override
  String get type => 'null';
}

class ObjNode extends Node {
  ObjNode({required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'obj';

  Map<String, Node> value; // Node as Expression

  @override
  void accept(Visitor fn) {
    value.updateAll((key, value) => value.visit(fn));
  }
}

class ArrNode extends Node {
  ArrNode({required this.value, Loc? loc}) : super(loc);

  @override
  String get type => 'arr';

  List<Node> value; // Expression[]

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < value.length; ++i) {
      value[i] = value[i].visit(fn);
    }
  }
}

class IdentifierNode extends Node with NameProp {
  IdentifierNode({required this.name, Loc? loc}) : super(loc);

  @override
  String get type => 'identifier';

  @override
  String name;
}

class CallNode extends Node {
  CallNode({required this.target, required this.args, Loc? loc}) : super(loc);

  @override
  String get type => 'call';

  Node target; // Expression
  List<Node> args; // Expression[]

  @override
  void accept(Visitor fn) {
    target = target.visit(fn);
    for (var i = 0; i < args.length; ++i) {
      args[i] = args[i].visit(fn);
    }
  }
}

class IndexNode extends Node {
  IndexNode({required this.target, required this.index, Loc? loc}) : super(loc);

  @override
  String get type => 'index';

  Node target; // Expression
  Node index; // Expression

  @override
  void accept(Visitor fn) {
    target = target.visit(fn);
    index = index.visit(fn);
  }
}

class PropNode extends Node {
  PropNode({required this.target, required this.name, Loc? loc}) : super(loc);

  @override
  String get type => 'prop';

  Node target; // Expression
  String name;

  @override
  void accept(Visitor fn) {
    target = target.visit(fn);
  }
}

class NamedTypeSourceNode extends Node {
  NamedTypeSourceNode({required this.name, this.inner, Loc? loc}) : super(loc);

  @override
  String get type => 'namedTypeSource';

  String name;
  Node? inner; // NamedTypeSourceNode | FnTypeSourceNode
}

class FnTypeSourceNode extends Node {
  FnTypeSourceNode({required this.args, required this.result, Loc? loc}) : super(loc);

  @override
  String get type => 'fnTypeSource';

  List<Node> args; // (NamedTypeSourceNode | FnTypeSourceNode)[]
  Node result; // NamedTypeSourceNode | FnTypeSourceNode
}