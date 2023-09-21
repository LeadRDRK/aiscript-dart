import 'scope.dart';
import '../core/line_column.dart';
import '../core/node.dart';
import '../parser/parser.dart';

/// A script execution context.
class Context {
  Context(this.scope, {this.source, this.moduleName, this.modulePath, this.parentContext});

  /// The source script.
  final String? source;

  /// The scope.
  final Scope scope;

  /// The module's name, if the context belongs to a module.
  final String? moduleName;

  /// The module's path, if the context belongs to a module.
  final String? modulePath;

  /// The parent context.
  final Context? parentContext;

  /// Get the line and column of a node's start location.
  /// 
  /// Returns `null` if [source] or [loc] is `null`.
  LineColumn? getLineColumn(Loc? loc) {
    if (source == null || loc == null) return null;
    return Parser.getLineColumn(source!, loc.start);
  }

  /// Check if this context is within a module with the specified path.
  /// 
  /// The check is done recursively through the parent context.
  bool isWithinModule(String path) {
    if (modulePath == path) return true;

    if (parentContext != null) {
      return parentContext!.isWithinModule(path);
    }
    else {
      return false;
    }
  }
}