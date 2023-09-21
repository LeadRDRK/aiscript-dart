import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'module_resolver.dart';
import '../parser/parser.dart';

/// A module resolver that loads the modules from files.
class FileModuleResolver implements ModuleResolver {
  const FileModuleResolver(this.parser, {
    this.paths = const [''],
    this.sanitizePaths = false,
    this.encoding = utf8,
    this.ext = '.aiscript'
  });

  /// The parser.
  final Parser parser;

  /// The module paths.
  /// 
  /// There must be at least 1 path entry for a non-module script to be
  /// able to resolve a module. The default value is an empty string, which means
  /// that relative paths are relative to the current working directory.
  /// Absolute paths are always allowed (unless [sanitizePaths] is enabled)
  /// 
  /// The order of the paths in the list determines their priority.
  /// However, the current module's path will always be prioritized first
  /// (if available).
  final List<String> paths;

  /// Whether to sanitize paths or not.
  /// 
  /// This will make the resolver ignore any paths that is an
  /// absolute path or a relative path that contains backtracking.
  /// 
  /// By default, it is disabled.
  final bool sanitizePaths;

  /// The encoding of the modules. Default: `utf8`
  final Encoding encoding;

  /// The extension of the module files, including the `.`
  /// 
  /// Default: `.aiscript`. Set it to `null` to disable the
  /// extension addition.
  final String? ext;

  @override
  Future<ResolvedModule> resolve(String path) async {
    final file = File(path);
    final script = await file.readAsString(encoding: encoding);
    final result = parser.parse(script);
    return ResolvedModule.fromParseResult(result);
  }

  @override
  Future<String?> resolvePath(String name, String? currentPath) async {
    if (sanitizePaths) {
      if (p.isAbsolute(name) ||
          p.split(name).any((part) => part == '..')) return null;
    }

    // Add and prioritize the current module directory if available
    final paths = currentPath == null ?
        this.paths :
        [p.dirname(currentPath), ...this.paths];
    
    // Find the file
    File? file;
    for (final path in paths) {
      var modulePath = p.normalize(p.join(path, name));
      if (ext != null) {
        if (p.extension(name) != ext) modulePath += ext!;
      }

      final f = File(modulePath);
      if (await f.exists()) {
        file = f;
        break;
      }
    }
    if (file == null) return null;

    return file.absolute.path;
  }
}