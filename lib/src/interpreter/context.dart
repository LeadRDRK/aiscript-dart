import 'scope.dart';
import '../core/line_column.dart';
import '../core/node.dart';
import '../parser/parser.dart';

/// A script execution context.
class Context {
  Context(this.scope, {this.source, this.moduleName});

  /// The source script.
  final String? source;

  /// The scope.
  final Scope scope;

  /// The module's name, if the context belongs to a module.
  final String? moduleName;

  /// Get the line and column of a node's start location.
  /// 
  /// Returns `null` if [source] or [loc] is `null`.
  LineColumn? getLineColumn(Loc? loc) {
    if (source == null || loc == null) return null;
    return Parser.getLineColumn(source!, loc.start);
  }
}