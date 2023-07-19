import '../core/node.dart';

class ChainedNode extends Node {
  ChainedNode({required this.parent, required this.chain, Loc? loc}) : super(loc);

  @override
  String get type => 'chained';

  Node parent;
  List<Node> chain;

  @override
  void accept(Visitor fn) {
    parent = parent.visit(fn);
    for (var i = 0; i < chain.length; ++i) {
      chain[i] = chain[i].visit(fn);
    }
  }
}

class CallChainNode extends Node {
  CallChainNode({required this.args, Loc? loc}) : super(loc);

  @override
  String get type => 'callChain';

  List<Node> args;

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < args.length; ++i) {
      args[i] = args[i].visit(fn);
    }
  }
}

class IndexChainNode extends Node {
  IndexChainNode({required this.index, Loc? loc}) : super(loc);

  @override
  String get type => 'indexChain';

  Node index;

  @override
  void accept(Visitor fn) {
    index = index.visit(fn);
  }
}

class PropChainNode extends Node with NameProp {
  PropChainNode({required this.name, Loc? loc}) : super(loc);

  @override
  String get type => 'propChain';

  @override
  String name;
}

class InfixNode extends Node {
  InfixNode({required this.operands, required this.operators, Loc? loc}) : super(loc);

  @override
  String get type => 'infix';

  List<Node> operands;
  List<String> operators;

  @override
  void accept(Visitor fn) {
    for (var i = 0; i < operands.length; ++i) {
      operands[i] = operands[i].visit(fn);
    }
  }
}