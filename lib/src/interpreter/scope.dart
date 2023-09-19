import 'dart:collection';
import 'value.dart';

/// An AiScript scope.
class Scope extends MapBase<String, Value> {
  Scope(this._layers, [String? name, this.parent])
  : name = name ?? (_layers.length == 1 ? '<root>' : '<anonymous>');

  factory Scope.child(Scope parent, [Map<String, Value>? states, String? name]) =>
      Scope([states ?? {}, ...parent._layers], name, parent);

  /// The parent scope.
  Scope? parent;
  /// The state layers. Contains states from its ancestors.
  final List<Map<String, Value>> _layers;
  /// The scope's name.
  String name;

  @override
  Value operator [](Object? key) => _firstLayerWithKey(key as String)[key]!;

  /// Alias for assign.
  @override
  void operator []=(String key, Value value) => assign(key, value);

  @override
  void clear() => _layers[0].clear();

  @override
  Iterable<String> get keys => _layers.fold<List<String>>([], (value, element) => value..addAll(element.keys));

  @override
  Iterable<Value> get values => _layers.fold<List<Value>>([], (value, element) => value..addAll(element.values));
  
  @override
  Value? remove(Object? key) => _layers[0].remove(key);

  /// Adds a variable to the scope.
  /// 
  /// Throws a [RuntimeError] if the variable already exists.
  void add(String key, Value value) {
    final layer = _layers[0];
    if (layer.containsKey(key)) {
      throw VariableExistsException(this, key);
    }
    layer[key] = value;
  }

  /// Assigns a new value to a variable.
  /// 
  /// Throws a [RuntimeError] if the variable doesn't exist.
  void assign(String key, Value value) => _firstLayerWithKey(key)[key] = value;

  Map<String, Value> _firstLayerWithKey(String key) {
    Map<String, Value> layer;

    try {
      layer = _layers.firstWhere((element) => element.containsKey(key));
    }
    catch (e) {
      throw NoSuchVariableException(this, key);
    }

    return layer;
  }
}

/// A scope exception.
abstract class ScopeException implements Exception {
  ScopeException(this.scope);

  /// The scope in which the exception occurred.
  final Scope scope;
}

/// A scope exception that occurred on a variable.
mixin VariableException on ScopeException {
  /// The key of the variable.
  String get key;
}

/// An exception that is thrown when attempting to add a variable that already exists.
class VariableExistsException extends ScopeException with VariableException {
  VariableExistsException(Scope scope, this.key)
  : super(scope);

  @override
  final String key;

  @override
  String toString() => 'Variable "$key" already exists in scope "${scope.name}"';
}

/// An exception that is thrown when attempting to access a variable that doesn't exist.
class NoSuchVariableException extends ScopeException with VariableException {
  NoSuchVariableException(Scope scope, this.key)
  : super(scope);

  @override
  final String key;

  @override
  String toString() => 'No such variable "$key" in scope "${scope.name}"';
}