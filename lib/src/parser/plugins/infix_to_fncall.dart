import 'package:aiscript/aiscript.dart';

abstract class _BaseOpInfo {
  _BaseOpInfo(this.priority);
  
  final int priority;
}

class _OpInfo extends _BaseOpInfo {
  _OpInfo(this.func, int priority) : super(priority);

  final String func;
}

class _ConstructOpInfo extends _BaseOpInfo {
  _ConstructOpInfo({required this.constructor, required int priority}) : super(priority);

  final Node Function(_InfixTreeNode infix) constructor;
}

final Map<String, _BaseOpInfo> _opInfos = {
  '*':  _OpInfo('Core:mul',  7),
  '^':  _OpInfo('Core:pow',  7),
  '/':  _OpInfo('Core:div',  7),
  '%':  _OpInfo('Core:mod',  7),
  '+':  _OpInfo('Core:add',  6),
  '-':  _OpInfo('Core:sub',  6),
  '==': _OpInfo('Core:eq',   4),
  '!=': _OpInfo('Core:neq',  4),
  '<':  _OpInfo('Core:lt',   4),
  '>':  _OpInfo('Core:gt',   4),
  '<=': _OpInfo('Core:lteq', 4),
  '>=': _OpInfo('Core:gteq', 4),
  '&&': _ConstructOpInfo(
    constructor: (infix) =>
      AndNode(
        left: _infixTreeToNode(infix.left),
        right: _infixTreeToNode(infix.right)
      ),
    priority: 3
  ),
  '||': _ConstructOpInfo(
    constructor: (infix) =>
      OrNode(
        left: _infixTreeToNode(infix.left),
        right: _infixTreeToNode(infix.right)
      ),
    priority: 3
  ),
};

class _InfixTreeNode extends Node {
  _InfixTreeNode(this.left, this.right, this.info) : super();

  @override
  String get type => 'infixTree';

  Node left;
  Node right;
  _BaseOpInfo info;
}

_InfixTreeNode _insertInfixTree(Node curTree, Node nextTree, _BaseOpInfo nextInfo) {
  if (curTree.type != 'infixTree') {
    return _InfixTreeNode(curTree, nextTree, nextInfo);
  }

  curTree as _InfixTreeNode;
  if (nextInfo.priority <= curTree.info.priority) {
    return _InfixTreeNode(curTree, nextTree, nextInfo);
  }
  else {
    return _InfixTreeNode(curTree.left, _insertInfixTree(curTree.right, nextTree, nextInfo), curTree.info);
  }
}

Node _infixTreeToNode(Node tree) {
  if (tree.type != 'infixTree') {
    return tree;
  }

  tree as _InfixTreeNode;
  final info = tree.info;
  if (info is _ConstructOpInfo) {
    return info.constructor(tree);
  }
  else {
    info as _OpInfo;
    return CallNode(
      target: IdentifierNode(name: info.func),
      args: [_infixTreeToNode(tree.left), _infixTreeToNode(tree.right)]
    );
  }
}

Node _transform(InfixNode node, LineColumnFn getLineColumn) {
  final infos = node.operators.map((e) {
    final info = _opInfos[e];
    if (info == null) {
      throw SyntaxError('no such operator: $e', getLineColumn(node.loc?.start ?? 0));
    }
    return info;
  }).toList();

  var tree = _InfixTreeNode(node.operands[0], node.operands[1], infos[0]);
  for (var i = 1; i < infos.length; ++i) {
    tree = _insertInfixTree(tree, node.operands[i + 1], infos[i]);
  }
  
  return _infixTreeToNode(tree)..loc = node.loc;
}

List<Node> infixToFnCall(List<Node> nodes, LineColumnFn getLineColumn) {
  for (var i = 0; i < nodes.length; ++i) {
    nodes[i] = nodes[i].visit((node) =>
      node is InfixNode ?
        _transform(node, getLineColumn) :
        node
    );
  }
  return nodes;
}