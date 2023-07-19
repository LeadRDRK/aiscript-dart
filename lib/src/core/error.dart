import 'line_column.dart';

abstract class AiScriptError implements Exception {
  AiScriptError(this.message, [this.pos]);

  /// The position at which the error occurred.
  LineColumn? pos;

  /// The type of the error.
  String get type;
  /// The error message.
  final String message;

  @override
  String toString() => '$type: $message${pos != null ? ' (at $pos)' : ''}';
}

class SyntaxError extends AiScriptError {
  SyntaxError(String message, LineColumn pos) : super(message, pos);

  @override
  String get type => 'SyntaxError';
}

class TypeError extends AiScriptError {
  TypeError(String message, [LineColumn? pos]) : super(message, pos);

  @override
  String get type => 'TypeError';
}

class RuntimeError extends AiScriptError {
  RuntimeError(String message, [LineColumn? pos]) : super(message, pos);

  @override
  String get type => 'RuntimeError';
}

class IndexOutOfRangeError extends RuntimeError {
  IndexOutOfRangeError(int index, int max, [LineColumn? pos])
  : super('index out of range (index: $index, max: $max)', pos);
}

class ReservedWordError extends SyntaxError {
  ReservedWordError(String word, LineColumn pos)
  : super('reserved word "$word" cannot be used as variable name', pos);
}