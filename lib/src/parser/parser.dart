import 'package:petitparser/petitparser.dart' show Token;
import 'parser_def.dart';

import 'plugins/infix_to_fncall.dart';
import 'plugins/set_attribute.dart';
import 'plugins/transform_chain.dart';
import 'plugins/validate_keyword.dart';

import '../core/node.dart';
import '../core/error.dart';
import '../core/line_column.dart';

typedef ParserPlugin = List<Node> Function(List<Node> nodes, LineColumnFn getLineColumn);
typedef LineColumnFn = LineColumn Function(int pos);

class ParseResult {
  const ParseResult(this.ast, this.source);
  final List<Node> ast;
  final String source;
}

/// An AiScript parser.
class Parser {
  static final _parser = AiScriptParserDefinition().build();
  static final _preParser = AiScriptPreprocessParserDefinition().build();

  List<ParserPlugin> validatePlugins;
  List<ParserPlugin> transformPlugins;

  Parser()
  : validatePlugins = [
      validateKeyword
    ],
    transformPlugins = [
      setAttribute,
      transformChain,
      infixToFnCall
    ];
  
  /// Adds a validation plugin.
  void addValidatePlugin(ParserPlugin plugin) {
    validatePlugins.add(plugin);
  }

  /// Adds a transformer plugin.
  void addTransformPlugin(ParserPlugin plugin) {
    transformPlugins.add(plugin);
  }
  
  /// Parses the script.
  /// 
  /// Returns a ParseResult which contains the preprocessed source
  /// and the AST of the script (which can be executed with Interpreter.exec)
  ParseResult parse(String input) {
    if (input.isEmpty) return ParseResult([], input);

    var res = _preParser.parse(input);
    if (res.isFailure) {
      final p = Token.lineAndColumnOf(res.buffer, res.position);
      throw SyntaxError(res.message, LineColumn.fromList(p));
    }

    final String source = res.value;
    res = _parser.parse(source);
    if (res.isFailure) {
      final p = Token.lineAndColumnOf(res.buffer, res.position);
      throw SyntaxError(res.message, LineColumn.fromList(p));
    }

    var nodes = res.value as List<Node>;
    getLineColumn(int pos) => Parser.getLineColumn(source, pos);

    for (final plugin in validatePlugins) {
      nodes = plugin(nodes, getLineColumn);
    }

    for (final plugin in transformPlugins) {
      nodes = plugin(nodes, getLineColumn);
    }

    return ParseResult(nodes, source);
  }

  static LineColumn getLineColumn(String source, int pos) =>
      LineColumn.fromList(Token.lineAndColumnOf(source, pos));

  static final _langVersionRegex = RegExp(r'^\s*\/\/\/\s*@\s*([a-zA-Z0-9_.-]+)(?:[\r\n][\s\S]*)?$');
  /// Gets the language version of the script (defined in the script as a comment)
  static String? getLangVersion(String input) =>
      _langVersionRegex.firstMatch(input)?[1];
}