import 'line_column.dart';

/// An AiScript error.
abstract class AiScriptError implements Exception {
  AiScriptError(this.message, [this.pos]);

  /// The position at which the error occurred.
  LineColumn? pos;

  /// The type of the error.
  String get type;
  
  /// The error message.
  final String message;

  @override
  String toString() => '$type: $message${pos == null ? '' : ' (at $pos)'}';
}

/// A syntax error.
class SyntaxError extends AiScriptError {
  SyntaxError(String message, LineColumn pos) : super(message, pos);

  @override
  String get type => 'SyntaxError';
}

/// A type error.
class TypeError extends AiScriptError {
  TypeError(String message, [LineColumn? pos]) : super(message, pos);

  @override
  String get type => 'TypeError';
}

/// A reserved word error.
class ReservedWordError extends SyntaxError {
  ReservedWordError(String word, LineColumn pos)
  : super('reserved word "$word" cannot be used as variable name', pos);
}