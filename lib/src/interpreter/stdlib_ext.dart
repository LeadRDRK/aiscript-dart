import 'scope.dart';
import 'value.dart';
import 'context.dart';
import 'runtime_error.dart';

final Map<String, Value> stdlibExt = {
  'require': NativeFnValue((args, state) async {
    final name = args.check<StrValue>(0).value;

    // Resolve the module's path
    final ctx = state.currentContext;
    String? currentPath = ctx.moduleName == null ? null : _getCurrentModulePath(ctx.scope);
    final path = await state.moduleResolver.resolvePath(name, currentPath);
    if (path == null) {
      throw RuntimeError(ctx, 'cannot find module "$name"');
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
    final context = Context(scope, source: resolved.source, moduleName: name);

    var module = await state.exec(resolved.ast, context);
    state.modules[path] = module;
    return module;
  })
};

String? _getCurrentModulePath(Scope scope) {
  final meta = scope['__module'];
  if (meta is ObjValue) {
    final path = meta.value['path'];
    if (path is StrValue) {
      return path.value;
    }
  }
  return null;
}