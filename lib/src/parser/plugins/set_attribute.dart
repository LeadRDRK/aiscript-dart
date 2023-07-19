import 'package:aiscript/aiscript.dart';

List<Node> setAttribute(List<Node> nodes, LineColumnFn getLineColumn) {
  final List<Node> result = [];
	final List<AttributeNode> stockedAttrs = [];

  for (final node in nodes) {
    if (node is AttributeNode) {
      stockedAttrs.add(node);
    }
    else if (node is DefinitionNode) {
      node.attr.addAll(stockedAttrs);
      stockedAttrs.clear();

      final expr = node.expr;
      if (expr is FnNode) {
        expr.children = setAttribute(expr.children, getLineColumn);
      }
      result.add(node);
    }
    else {
      if (stockedAttrs.isNotEmpty) {
        throw SyntaxError('invalid attribute', getLineColumn(stockedAttrs.last.loc?.start ?? 0));
      }

      if (node is FnNode) {
        node.children = setAttribute(node.children, getLineColumn);
      }
      else if (node is BlockNode) {
        node.statements = setAttribute(node.statements, getLineColumn);
      }
      result.add(node);
    }
  }

  if (stockedAttrs.isNotEmpty) {
    throw SyntaxError('invalid attribute', getLineColumn(stockedAttrs.last.loc?.start ?? 0));
  }
  return result;
}