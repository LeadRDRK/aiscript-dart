import 'package:aiscript/aiscript.dart';

Node _transform(ChainedNode node) {
  var parent = node.parent;
  for (final item in node.chain) {
    if (item is CallChainNode) {
      parent = CallNode(target: parent, args: item.args, loc: item.loc);
    }
    else if (item is IndexChainNode) {
      parent = IndexNode(target: parent, index: item.index, loc: item.loc);
    }
    else if (item is PropChainNode) {
      parent = PropNode(target: parent, name: item.name, loc: item.loc);
    }
  }

  return parent;
}

List<Node> transformChain(List<Node> nodes, _) {
  for (var i = 0; i < nodes.length; ++i) {
    nodes[i] = nodes[i].visit((node) =>
      node is ChainedNode ?
        _transform(node) :
        node
    );
  }
  return nodes;
}