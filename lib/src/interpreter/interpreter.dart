import 'package:petitparser/petitparser.dart';

import 'value.dart';
import 'fn_args.dart';
import 'scope.dart';
import 'stdlib.dart';
import 'primitive_props.dart';

import '../core/node.dart';
import '../core/ast.dart';
import '../core/error.dart';
import '../core/line_column.dart';

/// An AiScript interpreter state.
class Interpreter {
  /// The global scope.
  Scope scope;

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
  /// An interrupt request will occur when (stepCount++ % irqRate) == irqAt
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

  bool _aborted = false;
  final List<void Function()> _abortHandlers = [];
  final List<Future<void>> _timerFutures = [];

  /// Creates a new interpreter state.
  /// 
  /// The global scope will be initialized with the variable in vars,
  /// along with other default variables.
  /// By default, print() and readline() will not do anything. Provide
  /// an implementation in printFn and readlineFn to make them work.
  Interpreter(Map<String, Value> vars, {
    this.printFn,
    this.readlineFn,
    this.irqRate = 300,
    this.irqAt = 300 - 1,
    this.irqDuration = const Duration(milliseconds: 5),
    this.maxStep
  })
  : scope = Scope([{...vars, ...stdlib}]);

  /// Executes the script.
  /// 
  /// Returns the value returned from the script, or NullValue if
  /// there isn't any.
  Future<Value> exec(List<Node> script) async {
    if (script.isEmpty) return NullValue();
    await _collectNs(script);
    return _run(script, scope);
  }

  Future<Value> _eval(Node node, Scope scope) async {
    if (_aborted) return NullValue();
    if ((stepCount++ % irqRate) == irqAt) await Future.delayed(irqDuration);
    if (maxStep != null && stepCount > maxStep!) {
      throw RuntimeError('max step exceeded');
    }

    switch (node.type) {
      case 'call': node as CallNode;
        final callee = (await _eval(node.target, scope)).cast<FnValue>();
        final args = await Future.wait(node.args.map((e) => _eval(e, scope)));
        return call(callee, FnArgs(args), node.loc);

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
        scope.add(node.name, value);
        return NullValue();
      
      case 'identifier': node as IdentifierNode;
        return scope[node.name];

      case 'assign': node as AssignNode;
        final v = await _eval(node.expr, scope);
        final dest = node.dest;
        if (dest is IdentifierNode) {
          scope.assign(dest.name, v);
        }
        else if (dest is IndexNode) {
          final assignee = (await _eval(dest.target, scope)).cast<ArrValue>();
          final i = (await _eval(dest.index, scope)).cast<NumValue>().value.toInt();

          final list = assignee.value;
          if (i >= list.length) {
            // Simulate javascript array behavior
            var count = i - list.length;
            for (var j = 0; j <= count; ++j) {
              list.add(NullValue());
            }
          }
          list[i] = v;
        }
        else if (dest is PropNode) {
          final assignee = (await _eval(dest.target, scope)).cast<ObjValue>();
          assignee.value[dest.name] = v;
        }
        else {
          throw RuntimeError('invalid left-hand side in assignment', _lineColumn(dest.loc));
        }
        return NullValue();
      
      case 'addAssign': node as AddAssignNode;
        final target = (await _eval(node.dest, scope)).cast<NumValue>();
        final v = (await _eval(node.expr, scope)).cast<NumValue>();
        target.value += v.value;
        return NullValue();
      
      case 'subAssign': node as SubAssignNode;
        final target = (await _eval(node.dest, scope)).cast<NumValue>();
        final v = (await _eval(node.expr, scope)).cast<NumValue>();
        target.value -= v.value;
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
          throw RuntimeError('no such prop "${node.name}" in ${target.type}', _lineColumn(node.loc));
        }
        else {
          throw RuntimeError('cannot read prop "${node.name}" of ${target.type}', _lineColumn(node.loc));
        }
      
      case 'index': node as IndexNode;
        final target = (await _eval(node.target, scope)).cast<ArrValue>();
        final i = (await _eval(node.index, scope)).cast<NumValue>();
        final item = target.value.elementAtOrNull(i.value.toInt());
        if (item == null) {
          throw IndexOutOfRangeError(i.value.toInt(), target.value.length - 1, _lineColumn(node.loc));
        }
        return item;
      
      case 'not': node as NotNode;
        final v = (await _eval(node.expr, scope)).cast<BoolValue>();
        return BoolValue(!v.value);
      
      case 'fn': node as FnNode;
        return NormalFnValue(node.params.map((e) => e.name).toList(), node.children, scope);
      
      case 'block': node as BlockNode;
        return _run(node.statements, Scope.child(scope));
      
      case 'tmpl': node as TmplNode;
        var str = '';
        for (final x in node.tmpl) {
          if (x is String) {
            str += x;
          }
          else if (x is Node) {
            final v = await _eval(x, scope);
            String vStr = '';
            if (v is StrValue) {
              vStr = v.value;
            }
            else if (v is NumValue) {
              vStr = v.value.toString();
            }
            str += vStr;
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
        throw RuntimeError('invalid node type: ${node.type}', _lineColumn(node.loc));
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

  Future<void> _collectNsMember(NamespaceNode ns) async {
    final nsScope = Scope.child(scope);

    for (final node in ns.members) {
      if (node is DefinitionNode) {
        final v = await _eval(node.expr, nsScope);
        nsScope.add(node.name, v);
        scope.add('${ns.name}:${node.name}', v);
      }
      else if (node is NamespaceNode) {
        // TODO
      }
      else {
        throw RuntimeError('invalid ns member type: ${node.type}', _lineColumn(node.loc));
      }
    }
  }

  LineColumn? _lineColumn(Loc? loc) {
    if (source == null || loc == null) return null;
    return LineColumn.fromList(Token.lineAndColumnOf(source!, loc.start));
  }

  Value _passArgValue(Value arg) {
    if (arg is NumValue) {
      return NumValue(arg.value);
    }
    return arg;
  }

  /// Calls the function.
  /// 
  /// The optional loc value will be used for errors.
  /// If defined, error objects will include the location where the call occurred.
  Future<Value> call(FnValue fn, [List<Value> args = const [], Loc? loc]) async {
    final passedArgs = args.map((value) => _passArgValue(value));
    if (fn is NativeFnValue) {
      try {
        return await fn.nativeFn(FnArgs(passedArgs.toList()), this);
      }
      catch (e) {
        if (e is AiScriptError) {
          e.pos = _lineColumn(loc);
        }
        rethrow;
      }
    }
    else {
      fn as NormalFnValue;
      final Map<String, Value> argVars = {};
      for (var i = 0; i < fn.params.length; ++i) {
        argVars[fn.params[i]] = passedArgs.elementAtOrNull(i) ?? NullValue();
      }
      final scope = Scope.child(fn.scope, argVars);
      return _run(fn.statements, scope);
    }
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

  /// Runs the Async timers.
  Future<void> runTimers() async {
    await Future.wait(_timerFutures);
    _timerFutures.clear();
  }

  /// Adds a future for a timer.
  void addTimerFuture(Future<void> future) {
    _timerFutures.add(future);
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