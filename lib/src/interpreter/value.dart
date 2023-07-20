import 'interpreter.dart';
import 'fn_args.dart';
import 'scope.dart';
import '../core/node.dart';
import '../core/error.dart';

/// Origin statement of a value.
enum OriginStatement {
  /// The value was not returned using any statement.
  none,
  /// The value was returned using the 'return' statement.
  return_,
  /// The value was returned using the 'break' statement.
  break_,
  /// The value was returned using the 'continue' statement.
  continue_
}

/// An AiScript value.
abstract class Value {
  Value([this.origin = OriginStatement.none]);

  /// The type of the value.
  String get type;

  /// The statement that this value was returned from.
  OriginStatement origin;
  /// The value's attributes
  List<Attribute>? attributes;

  /// Cast a Value to another Value type.
  /// 
  /// Throws a TypeError if the value cannot be casted to
  /// the desired type.
  T cast<T extends Value>() {
    assert(T != Never);
    if (this is T) {
      return this as T;
    }
    else {
      throw TypeError('expected ${T.toString()}, got $runtimeType');
    }
  }

  factory Value.fromJson(dynamic v) {
    if (v == null)   return NullValue();
    if (v is bool)   return BoolValue(v);
    if (v is num)    return NumValue(v);
    if (v is String) return StrValue(v);
    if (v is List)   return ArrValue.fromJson(v);
    if (v is Map<String, dynamic>) return ObjValue.fromJson(v);
    
    return NullValue();
  }

  dynamic toJson();
}

mixin PrimitiveValue<T> on Value {
  /// The value of a primitive value object.
  T get value;

  @override
  bool operator ==(Object other) => other is PrimitiveValue &&
      other.runtimeType == runtimeType &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value.toString();
}

class Attribute {
  Attribute(this.name, this.value);

  /// The name of the attribute.
  String name;
  /// The value of the attribute.
  Value value;
}

/// An AiScript null value.
class NullValue extends Value with PrimitiveValue<void> {
  NullValue([origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'null';

  @override
  void value;

  @override
  void toJson() {}
}

/// An AiScript bool value.
class BoolValue extends Value with PrimitiveValue<bool> {
  BoolValue(this.value, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'bool';

  @override
  final bool value;

  @override
  bool toJson() => value;
}

/// An AiScript num value.
class NumValue extends Value with PrimitiveValue<num> {
  NumValue(this.value, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'num';

  @override
  num value;

  @override
  num toJson() => value;
}

/// An AiScript str value.
class StrValue extends Value with PrimitiveValue<String> {
  StrValue(this.value, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'str';

  @override
  final String value;

  @override
  String toJson() => value;
}

mixin DeepEqValue<T> on PrimitiveValue<T> {
  /// Checks if a value deeply equals to another.
  /// Intended for array and object values.
  bool deepEq(Value other);
}

/// An AiScript arr value.
class ArrValue extends Value with PrimitiveValue<List<Value>>, DeepEqValue {
  ArrValue(this.value, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'arr';

  @override
  final List<Value> value;

  ArrValue.fromJson(List list)
  : value = list.map((e) => Value.fromJson(e)).toList();

  @override
  List<dynamic> toJson() => value.map((e) => e.toJson()).toList();

  @override
  bool deepEq(Value other) {
    if (other is! ArrValue) return false;
    for (var i = 0; i < value.length; ++i) {
      final v = value[i];
      final equals = (v is DeepEqValue) ?
          v.deepEq(other.value[i]) :
          v == other.value[i];
      if (!equals) return false;
    }
    return true;
  }
}

/// An AiScript obj value.
class ObjValue extends Value with PrimitiveValue<Map<String, Value>>, DeepEqValue {
  ObjValue(this.value, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'obj';

  @override
  final Map<String, Value> value;

  ObjValue.fromJson(Map<String, dynamic> json)
  : value = json.map((key, value) => MapEntry(key, Value.fromJson(value)));

  @override
  Map<String, dynamic> toJson() =>
      value.map((key, value) => MapEntry(key, value.toJson()));
  
  @override
  bool deepEq(Value other) {
    if (other is! ObjValue) return false;
    for (final k in value.keys) {
      final otherValue = other.value[k];
      if (otherValue == null) return false;

      final equals = (otherValue is DeepEqValue) ?
          otherValue.deepEq(value[k]!) :
          otherValue == value[k];
      if (!equals) return false;
    }
    return true;
  }
}

/// Base class for fn values.
abstract class FnValue extends Value {
  FnValue([origin = OriginStatement.none]) : super(origin);

  @override
  String get type => 'fn';

  /// The function's parameters.
  List<String>? get params;
  /// The statements in the function's body.
  List<Node>? get statements;
  /// The native function.
  Future<Value> Function(FnArgs args, Interpreter state)? get nativeFn;

  @override
  String toJson() => '<function>';

  @override
  String toString() => 'fn<...>';
}

/// A native fn value.
class NativeFnValue extends FnValue {
  NativeFnValue(this.nativeFn, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  final Future<Value> Function(FnArgs args, Interpreter state) nativeFn;

  @override
  List<String>? get params => null;

  @override
  List<Node>? get statements => null;
}

/// An AiScript fn value.
class NormalFnValue extends FnValue {
  NormalFnValue(this.params, this.statements, this.scope, [OriginStatement origin = OriginStatement.none]) : super(origin);

  @override
  Future<Value> Function(FnArgs args, Interpreter state)? get nativeFn => null;

  @override
  List<String> params;

  @override
  List<Node> statements;

  Scope scope;
}