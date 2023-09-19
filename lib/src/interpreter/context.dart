import 'scope.dart';
import '../core/line_column.dart';
import '../core/node.dart';
import '../parser/parser.dart';

/// A script execution context.
class Context {
  Context(this.scope, {this.source, this.isModule = false});

  /// The source script.
  final String? source;

  /// The scope.
  final Scope scope;

  /// Whether the script is a module.
  final bool isModule;

  /// Get the line and column of a node's start location.
  /// 
  /// Returns `null` if [source] or [loc] is `null`.
  LineColumn? getLineColumn(Loc? loc) {
    if (source == null || loc == null) return null;
    return Parser.getLineColumn(source!, loc.start);
  }
}