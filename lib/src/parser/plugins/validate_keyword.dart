import 'package:aiscript/aiscript.dart';

const _reservedWords = {
  'null',
  'true',
  'false',
  'each',
  'for',
  'loop',
  'break',
  'continue',
  'match',
  'if',
  'elif',
  'else',
  'return',
  'eval',
  'var',
  'let',
  'exists',

  // future
  'fn',
  'namespace',
  'meta',
  'attr',
  'attribute',
  'static',
  'class',
  'struct',
  'module',
  'while',
  'import',
  'export'
};

List<Node> validateKeyword(List<Node> nodes, LineColumnFn getLineColumn) {
  for (var i = 0; i < nodes.length; ++i) {
    nodes[i].visit((node) {
      if (node is NameProp || node is OptionalNameProp) {
        final name = (node as dynamic).name;
        if (name != null && _reservedWords.contains(name)) {
          throw ReservedWordError(name, getLineColumn(node.loc?.start ?? 0));
        }
      }
      else if (node is FnNode) {
        for (final param in node.params) {
          if (_reservedWords.contains(param.name)) {
            throw ReservedWordError(param.name, getLineColumn(node.loc?.start ?? 0));
          }
        }
      }

      return node;
    });
  }
  return nodes;
}