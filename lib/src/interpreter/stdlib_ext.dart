import '../core/error.dart';
import 'scope.dart';
import 'value.dart';

final Map<String, Value> stdlibExt = {
  'require': NativeFnValue((args, state) async {
    final name = args.check<StrValue>(0).value;

    // Resolve the module's path
    String? currentPath = _getCurrentModulePath(state.currentExecScope);
    final path = await state.moduleResolver.resolvePath(name, currentPath);
    if (path == null) {
      throw RuntimeError('cannot find module "$name"');
    }

    // Check if it's already loaded
    final loadedModule = state.modules[path];
    if (loadedModule != null) return loadedModule;

    // Resolve the module
    final resolved = await state.moduleResolver.resolve(path);

    // Create a scope for the module
    ObjValue moduleObj = ObjValue({
      'path': StrValue(path)
    });
    final scope = Scope.child(state.scope, {'__module': moduleObj}, name);

    try {
      var module = await state.exec(resolved.ast, scope);
      state.modules[path] = module;
      return module;
    }
    catch (e) {
      // TODO: error location in module, rethrow original error
      if (e is AiScriptError) {
        throw RuntimeError('error while executing module "$name": ${e.message}');
      }
      else {
        // Rethrow other errors
        rethrow;
      }
    }
  })
};

String? _getCurrentModulePath(Scope scope) {
  if (scope.containsKey('__module')) {
    final meta = scope['__module'];
    if (meta is ObjValue) {
      final path = meta.value['path'];
      if (path is StrValue) {
        return path.value;
      }
    }
  }
  return null;
}