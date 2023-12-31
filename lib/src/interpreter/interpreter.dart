import 'value.dart';
import 'fn_args.dart';
import 'scope.dart';
import 'stdlib.dart';
import 'stdlib_ext.dart';
import 'primitive_props.dart';
import 'module_resolver.dart';
import 'dummy_module_resolver.dart';
import 'context.dart';
import 'runtime_error.dart';

import '../core/node.dart';
import '../core/ast.dart';
import '../core/error.dart';

/// An AiScript interpreter state.
class Interpreter {
  /// The global scope.
  final Scope scope;

  Context? _currentContext;
  /// The current script execution context.
  /// 
  /// This is meant to be accessed inside of a native function
  /// to retrieve the current execution context. Outside of an
  /// execution context, accessing it will result in an error.
  Context get currentContext => _currentContext!;

  /// The print function.
  void Function(Value)? printFn;
  /// The readline function.
  Future<String> Function(String)? readlineFn;
  /// The script's source (as returned by the Parser).
  String? source;

  /// The interrupt rate.
  /// Default: 300
  int irqRate;
  /// The step to interrupt at.
  /// An interrupt request will occur when `(stepCount++ % irqRate) == irqAt`
  /// 
  /// Default: 299
  int irqAt;
  /// The interrupt duration.
  /// Default: 5 milliseconds
  Duration irqDuration;

  /// The maximum step before execution stops.
  int? maxStep;
  /// The current step count.
  int stepCount = 0;

  /// The module resolver used by `require()`.
  final ModuleResolver moduleResolver;

  /// The loaded modules.
  /// 
  /// Module scripts will be run once when they're first required, then
  /// stored in this map for later use. Therefore, any modules present
  /// in this map will skip the module resolving step.
  final Map<String, Value> modules = {};

  bool _aborted = false;
  final List<void Function()> _abortHandlers = [];

  /// Creates a new interpreter state.
  /// 
  /// The global scope will be initialized with the variable in vars,
  /// along with other default variables.
  /// 
  /// By default, print() and readline() will not do anything. Provide
  /// an implementation in [printFn] and [readlineFn] to make them work.
  /// 
  /// [disableExtensions] can be set to `true` to disable extensions in
  /// the standard library.
  /// 
  /// [moduleResolver] defaults to [DummyModuleResolver], which is a module
  /// resolver that always fails to resolve any module. Implement your own
  /// [ModuleResolver] or use the included [FileModuleResolver] to make it work.
  Interpreter(Map<String, Value> vars, {
    this.printFn,
    this.readlineFn,
    this.irqRate = 300,
    this.irqAt = 300 - 1,
    this.irqDuration = const Duration(milliseconds: 5),
    this.maxStep,
    this.moduleResolver = const DummyModuleResolver(),
    bool disableExtensions = false
  })
  : scope = Scope([{
      ...vars,
      ...stdlib,
      if (!disableExtensions) ...stdlibExt
    }]);

  /// Executes the script.
  /// 
  /// Returns the value returned from the script, or NullValue if
  /// there isn't any.
  /// 
  /// [context] can be set to modify the script execution context.
  /// By default, a context is created with the source set to `this.source`,
  /// and a child scope created from the root scope for the execution
  /// (which differs from the original implementation).
  /// Create a custom [context] that uses the root scope or a different scope
  /// to override this behavior.
  Future<Value> exec(List<Node> script, [Context? context]) async {
    if (script.isEmpty) return NullValue();

    context ??= Context(Scope.child(scope), source: source);
    final prevContext = _currentContext;
    _currentContext = context;

    Value res;
    try {
      await _collectNs(script);
      res = await _run(script, context.scope);
    }
    finally {
      _currentContext = prevContext;
    }

    return res;
  }

  Future<Value> _eval(Node node, Scope scope) async {
    try {
      return await __eval(node, scope);
    }
    on AiScriptError catch (e) {
      e.pos ??= currentContext.getLineColumn(node.loc);
      rethrow;
    }
    on ScopeException catch (e) {
      final ctx = currentContext;
      throw RuntimeError(ctx, e.toString(), ctx.getLineColumn(node.loc));
    }
  }

  Future<Value> __eval(Node node, Scope scope) async {
    if (_aborted) return NullValue();
    if ((stepCount++ % irqRate) == irqAt) await Future.delayed(irqDuration);

    final ctx = currentContext;
    if (maxStep != null && stepCount > maxStep!) {
      throw RuntimeError(ctx, 'max step exceeded');
    }

    switch (node.type) {
      case 'call': node as CallNode;
        final callee = (await _eval(node.target, scope)).cast<FnValue>();
        final args = await Future.wait(node.args.map((e) => _eval(e, scope)));
        return call(callee, args: args, loc: node.loc);

      case 'if': node as IfNode;
        final cond = (await _eval(node.cond, scope)).cast<BoolValue>();
        if (cond.value) {
          return _eval(node.then, scope);
        }
        else {
          for (final elseif in node.elseifBlocks) {
            final cond = (await _eval(elseif.cond, scope)).cast<BoolValue>();
            if (cond.value) {
              return _eval(elseif.then, scope);
            }
          }
          final elseBlock = node.elseBlock;
          if (elseBlock != null) {
            return _eval(elseBlock, scope);
          }
          return NullValue();
        }
      
      case 'match': node as MatchNode;
        final about = await _eval(node.about, scope);
        for (final qa in node.qs) {
          final q = await _eval(qa.q, scope);
          if (about == q) {
            return _eval(qa.a, scope);
          }
        }
        final defaultRes = node.defaultRes;
        if (defaultRes != null) {
          return _eval(defaultRes, scope);
        }
        return NullValue();
      
      case 'loop': node as LoopNode;
        while (true) {
          final v = await _run(node.statements, Scope.child(scope));
          if (v.origin == OriginStatement.break_) {
            break;
          }
          else if (v.origin == OriginStatement.return_) {
            return v;
          }
        }
        return NullValue();
      
      case 'for': node as ForNode;
        if (node.times != null) {
          final times = (await _eval(node.times!, scope)).cast<NumValue>();
          for (var i = 0; i < times.value; ++i) {
            final v = await _eval(node.body, Scope.child(scope));
            if (v.origin == OriginStatement.break_) {
              break;
            }
            else if (v.origin == OriginStatement.return_) {
              return v;
            }
          }
        }
        else {
          final from = (await _eval(node.from!, scope)).cast<NumValue>();
          final to = (await _eval(node.to!, scope)).cast<NumValue>();
          for (var i = from.value; i < from.value + to.value; ++i) {
            final v = await _eval(node.body, Scope.child(scope, {node.varName!: NumValue(i)}));
            if (v.origin == OriginStatement.break_) {
              break;
            }
            else if (v.origin == OriginStatement.return_) {
              return v;
            }
          }
        }
        return NullValue();
      
      case 'each': node as EachNode;
        final items = (await _eval(node.items, scope)).cast<ArrValue>();
        for (final item in items.value) {
          final v = await _eval(node.body, Scope.child(scope, {node.varName: item}));
          if (v.origin == OriginStatement.break_) {
            break;
          }
          else if (v.origin == OriginStatement.return_) {
            return v;
          }
        }
        return NullValue();
      
      case 'def': node as DefinitionNode;
        final value = await _eval(node.expr, scope);
        if (node.attr.isNotEmpty) {
          value.attributes = await Future.wait(
            node.attr.map((attr) async => Attribute(attr.name, await _eval(attr.value, scope)))
          );
        }
        value.isMutable = node.mut;
        scope.add(node.name, value);
        return NullValue();
      
      case 'identifier': node as IdentifierNode;
        return scope.get(node.name);

      case 'assign': node as AssignNode;
        final dest = node.dest;
        final value = await _eval(node.expr, scope);
        await _assign(scope, dest, value);
        return NullValue();
      
      case 'addAssign': node as AddAssignNode;
        final target = (await _eval(node.dest, scope)).cast<NumValue>();
        final v = (await _eval(node.expr, scope)).cast<NumValue>();
        await _assign(scope, node.dest, NumValue(target.value + v.value));
        return NullValue();
      
      case 'subAssign': node as SubAssignNode;
        final target = (await _eval(node.dest, scope)).cast<NumValue>();
        final v = (await _eval(node.expr, scope)).cast<NumValue>();
        await _assign(scope, node.dest, NumValue(target.value - v.value));
        return NullValue();
      
      case 'null': node as NullNode;
        return NullValue();

      case 'bool': node as BoolNode;
        return BoolValue(node.value);
      
      case 'num': node as NumNode;
        return NumValue(node.value);
      
      case 'str': node as StrNode;
        return StrValue(node.value);
      
      case 'arr': node as ArrNode;
        return ArrValue(await Future.wait(node.value.map((e) => _eval(e, scope))));
      
      case 'obj': node as ObjNode;
        final Map<String, Value> obj = {};
        for (final item in node.value.entries) {
          obj[item.key] = await _eval(item.value, scope);
        }
        return ObjValue(obj);
      
      case 'prop': node as PropNode;
        final target = await _eval(node.target, scope);
        if (target is ObjValue) {
          return target.value.containsKey(node.name) ? target.value[node.name]! : NullValue();
        }
        else if (target is PrimitiveValue && primitiveProps.containsKey(target.type)) {
          final props = primitiveProps[target.type]!;
          if (props.containsKey(node.name)) return props[node.name]!(target);
          throw RuntimeError(ctx, 'no such prop "${node.name}" in ${target.type}');
        }
        else {
          throw RuntimeError(ctx, 'cannot read prop "${node.name}" of ${target.type}');
        }
      
      case 'index': node as IndexNode;
        final target = await _eval(node.target, scope);
        final index = await _eval(node.index, scope);
        if (target is ArrValue) {
          final i = index.cast<NumValue>().value.toInt();
          final item = target.value.elementAtOrNull(i);
          if (item == null) {
            throw IndexOutOfRangeError(ctx, i, target.value.length);
          }
          return item;
        }
        else if (target is ObjValue) {
          final i = index.cast<StrValue>().value;
          return target.value[i] ?? NullValue();
        }
        else {
          throw RuntimeError(ctx, 'cannot read prop "$index" of ${target.type}');
        }
      
      case 'not': node as NotNode;
        final v = (await _eval(node.expr, scope)).cast<BoolValue>();
        return BoolValue(!v.value);
      
      case 'fn': node as FnNode;
        return NormalFnValue(node.params.map((e) => e.name).toList(), node.children, scope);
      
      case 'block': node as BlockNode;
        return _run(node.statements, Scope.child(scope));
      
      case 'exists': node as ExistsNode;
        return BoolValue(scope.containsKey(node.identifier.name));

      case 'tmpl': node as TmplNode;
        var str = '';
        for (final x in node.tmpl) {
          if (x is String) {
            str += x;
          }
          else if (x is Node) {
            final v = await _eval(x, scope);
            str += v.toString();
          }
        }
        return StrValue(str);
      
      case 'return': node as ReturnNode;
        final v = await _eval(node.expr, scope);
        return v..origin = OriginStatement.return_;
      
      case 'break': node as BreakNode;
        return NullValue(OriginStatement.break_);

      case 'continue': node as ContinueNode;
        return NullValue(OriginStatement.continue_);
      
      case 'ns': node as NamespaceNode;
        // nop
        return NullValue();
      
      case 'meta': node as MetaNode;
        // nop
        return NullValue();
      
      case 'and': node as AndNode;
        final left = (await _eval(node.left, scope)).cast<BoolValue>();
        if (!left.value) {
          return left..clearOrigin();
        }
        else {
          final right = (await _eval(node.right, scope)).cast<BoolValue>();
          return right..clearOrigin();
        }
      
      case 'or': node as OrNode;
        final left = (await _eval(node.left, scope)).cast<BoolValue>();
        if (left.value) {
          return left..clearOrigin();
        }
        else {
          final right = (await _eval(node.right, scope)).cast<BoolValue>();
          return right..clearOrigin();
        }

      default:
        throw RuntimeError(ctx, 'invalid node type: ${node.type}');
    }
  }

  Future<void> _assign(Scope scope, Node dest, Value value) async {
    final ctx = currentContext;
    if (dest is IdentifierNode) {
      scope.assign(dest.name, value);
    }
    else if (dest is IndexNode) {
      final assignee = await _eval(dest.target, scope);
      final index = await _eval(dest.index, scope);
      
      if (assignee is ArrValue) {
        final i = index.cast<NumValue>().value.toInt();
        final list = assignee.value;
        if (i >= list.length) {
          // Simulate javascript array behavior
          var count = i - list.length;
          for (var j = 0; j <= count; ++j) {
            list.add(NullValue());
          }
        }
        list[i] = value;
      }
      else if (assignee is ObjValue) {
        final i = index.cast<StrValue>().value;
        assignee.value[i] = value;
      }
      else {
        throw RuntimeError(ctx, 'cannot read prop "$index" of ${assignee.type}');
      }
    }
    else if (dest is PropNode) {
      final assignee = (await _eval(dest.target, scope)).cast<ObjValue>();
      assignee.value[dest.name] = value;
    }
    else {
      throw RuntimeError(ctx, 'invalid left-hand side in assignment', ctx.getLineColumn(dest.loc));
    }
  }

  Future<Value> _run(List<Node> script, Scope scope) async {
    Value v = NullValue();

    for (final node in script) {
      v = await _eval(node, scope);
      if (v.origin != OriginStatement.none) {
        return v;
      }
    }

    return v;
  }

  Future<void> _collectNs(List<Node> script) async {
    for (final node in script) {
      if (node is NamespaceNode) {
        await _collectNsMember(node);
      }
    }
  }

  Future<Map<String, Value>> _collectNsMember(NamespaceNode ns, [Scope? scope, String nsPrefix = '']) async {
    nsPrefix += '${ns.name}:';
    final nsScope = Scope.child(scope ?? this.scope);
    final ctx = currentContext;

    for (final node in ns.members) {
      if (node is DefinitionNode) {
        if (node.mut) {
          throw RuntimeError(ctx, 'namespaces cannot include mutable variable: '
              '${node.name}', ctx.getLineColumn(node.loc));
        }

        final v = await _eval(node.expr, nsScope);
        v.isMutable = node.mut;
        nsScope.add(node.name, v);
        this.scope.add('$nsPrefix${node.name}', v);
      }
      else if (node is NamespaceNode) {
        final layer = await _collectNsMember(node, nsScope, nsPrefix);
        layer.forEach((key, value) {
          nsScope.add('${node.name}:$key', value);
        });
      }
      else {
        throw RuntimeError(ctx, 'invalid ns member type: ${node.type}', ctx.getLineColumn(node.loc));
      }
    }

    return nsScope.top;
  }

  /// Calls the function.
  /// 
  /// The optional [loc] value will be used for errors.
  /// If defined, error objects will include the location where the call occurred.
  /// 
  /// [context] can be set to modify the function's execution context.
  /// By default it has the same behavior as [exec], however if it's called inside
  /// of an execution context, it will not assign its own context.
  /// Setting the [context] explicitly overrides this behavior.
  Future<Value> call(FnValue fn, {List<Value> args = const [], Loc? loc, Context? context}) async {
    Context? prevContext;
    bool setContext = _currentContext == null || context != null;
    if (setContext) {
      prevContext = _currentContext;
      _currentContext = context ?? Context(Scope.child(scope), source: source);
    }

    Value res;
    try {
      if (fn is NativeFnValue) {
        try {
          res = await fn.nativeFn(FnArgs(args), this);
        }
        on AiScriptError catch (e) {
          e.pos ??= currentContext.getLineColumn(loc);
          rethrow;
        }
      }
      else {
        fn as NormalFnValue;
        final Map<String, Value> argVars = {};
        for (var i = 0; i < fn.params.length; ++i) {
          argVars[fn.params[i]] = args.elementAtOrNull(i) ?? NullValue();
        }
        final scope = Scope.child(fn.scope, argVars);
        res = await _run(fn.statements, scope);
      }
    }
    finally {
      if (setContext) _currentContext = prevContext;
    }

    return res;
  }

  static dynamic _nodeToDart(Node node) {
    switch (node.type) {
      case 'arr': node as ArrNode;
        return node.value.map((item) => _nodeToDart(item));

      case 'bool': node as BoolNode;
        return node.value;

      case 'null': node as NullNode;
        return null;

      case 'num': node as NumNode;
        return node.value;

      case 'obj': node as ObjNode;
        return node.value.map((key, value) => MapEntry(key, _nodeToDart(value)));

      case 'str': node as StrNode;
        return node.value;

      default:
        return null;
    }
  }

  /// Collects metadata from the script.
  static Map<String, dynamic> collectMetadata(List<Node> script) {
    final Map<String, dynamic> meta = {};

    for (final node in script) {
      if (node is MetaNode) {
        meta[node.name ?? ''] = _nodeToDart(node.value);
      }
    }
    
    return meta;
  }

  /// Registers an abort handler, which will be called when execution is aborted.
  void registerAbortHandler(void Function() handler) {
    _abortHandlers.add(handler);
  }

  /// Unregisters an abort handler.
  void unregisterAbortHandler(void Function() handler) {
    _abortHandlers.remove(handler);
  }

  /// Aborts the current execution.
  void abort() {
    _aborted = true;
    for (final handler in _abortHandlers) {
      handler();
    }
    _abortHandlers.clear();
  }
}