import 'scope.dart';
import 'value.dart';
import 'context.dart';
import 'runtime_error.dart';

final Map<String, Value> stdlibExt = {
  'require': NativeFnValue((args, state) async {
    final name = args.check<StrValue>(0).value;

    // Resolve the module's path
    final currentContext = state.currentContext;
    String? currentPath = currentContext.modulePath;
    
    final path = await state.moduleResolver.resolvePath(name, currentPath);
    if (path == null) {
      throw RuntimeError(currentContext, 'cannot find module "$name"');
    }

    // Check for circular dependency
    if (currentContext.isWithinModule(path)) {
      throw RuntimeError(currentContext, 'circular dependency between '
          '${_formatModuleName(currentContext)} and "$name"');
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
    final context = Context(
      scope,
      source: resolved.source,
      moduleName: name,
      modulePath: path,
      parentContext: currentContext
    );

    var module = await state.exec(resolved.ast, context);
    state.modules[path] = module;
    return module;
  })
};

String _formatModuleName(Context ctx) =>
    ctx.moduleName == null ? '<script>' : '"${ctx.moduleName}"';