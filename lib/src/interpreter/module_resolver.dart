import '../core/node.dart';
import '../parser/parser.dart';

abstract class ModuleResolver {
  /// Resolves a module.
  /// 
  /// [path] is the name of the module (as returned by calling [resolvePath])
  /// 
  /// Returns `null` if the module was not found.
  Future<ResolvedModule> resolve(String path);

  /// Resolves the full name a module.
  /// 
  /// [name] is the name of the module
  /// (as specified when calling `require`)
  /// 
  /// [currentPath] is the `module.path` value of the current module,
  /// if `require` was called inside of a module.
  ///
  /// This will be the name that will be used to store loaded modules.
  /// It is expected to return the same name for identifiers that refers to
  /// the same module.
  Future<String?> resolvePath(String name, String? currentPath);
}

/// Data of a module resolved by a ModuleResolver.
class ResolvedModule {
  ResolvedModule(this.ast, [this.source]);

  ResolvedModule.fromParseResult(ParseResult res)
  : ast = res.ast,
    source = res.source;

  // The parsed AST of the module script.
  final List<Node> ast;

  // The source script that produced the resulting AST.
  final String? source;
}