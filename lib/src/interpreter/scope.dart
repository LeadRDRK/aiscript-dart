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
  Value? operator [](Object? key) {
    final layer = _firstLayerWithKey(key as String);
    return layer == null ? null : layer[key];
  }

  /// Alias for assign.
  @override
  void operator []=(String key, Value value) => assign(key, value);

  @override
  void clear() => _layers[0].clear();

  @override
  Iterable<String> get keys => _layers.fold<Set<String>>({}, (value, element) => value..addAll(element.keys));

  @override
  bool containsKey(Object? key) => _firstLayerWithKey(key as String) != null;

  @override
  bool get isEmpty => _layers.every((layer) => layer.isEmpty);

  @override
  bool get isNotEmpty => !isEmpty;
  
  @override
  Value? remove(Object? key) => _layers[0].remove(key);

  /// The top layer of the scope.
  Map<String, Value> get top => _layers[0];

  /// Adds a variable to the scope.
  /// 
  /// Throws a [VariableExistsException] if the variable already exists.
  void add(String key, Value value) {
    final layer = _layers[0];
    if (layer.containsKey(key)) {
      throw VariableExistsException(this, key);
    }
    layer[key] = value;
  }

  /// Gets a variable.
  /// 
  /// Throws a [NoSuchVariableException] if the variable doesn't exist.
  /// Use the [] operator instead if you want it to return `null` instead
  /// of throwing an exception.
  Value get(String key) {
    final layer = _firstLayerWithKey(key);
    if (layer == null) {
      throw NoSuchVariableException(this, key);
    }
    return layer[key]!;
  }

  /// Assigns a new value to a variable.
  /// 
  /// Throws a [NoSuchVariableException] if the variable doesn't exist,
  /// [ImmutableVariableException] if the variable is immutable.
  void assign(String key, Value value) {
    final layer = _firstLayerWithKey(key);
    if (layer == null) {
      throw NoSuchVariableException(this, key);
    }
    if (layer[key]!.isMutable == false) {
      throw ImmutableVariableException(this, key);
    }
    layer[key] = value;
  }

  Map<String, Value>? _firstLayerWithKey(String key) {
    for (final layer in _layers) {
      if (layer.containsKey(key)) return layer;
    }
    return null;
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

/// An exception that is thrown when attempting to assign a value to an immutable variable.
class ImmutableVariableException extends ScopeException with VariableException {
  ImmutableVariableException(Scope scope, this.key)
  : super(scope);

  @override
  final String key;

  @override
  String toString() => 'Attempt to assign value to immutable variable "$key"';
}