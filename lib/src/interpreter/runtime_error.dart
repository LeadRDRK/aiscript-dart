import '../core/error.dart';
import '../core/line_column.dart';
import 'context.dart';

/// A runtime error.
class RuntimeError extends AiScriptError {
  RuntimeError(this.context, String message, [LineColumn? pos]) : super(message, pos);

  /// The execution context in which the error occurred.
  final Context context;

  @override
  String get type => 'RuntimeError';

  @override
  String toString() =>
      '${super.toString()}${context.moduleName == null ? '' : ' [in module "${context.moduleName}"]'}';
}

/// An index out of range error.
class IndexOutOfRangeError extends RuntimeError {
  IndexOutOfRangeError(Context context, int index, int length, [LineColumn? pos])
  : super(context, 'index out of range (index: $index, length: $length)', pos);
}