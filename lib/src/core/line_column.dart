/// The line and column position in a script.
class LineColumn {
  /// Creates a new LineColumn.
  LineColumn(this.line, this.column);
  /// Creates a new LineColumn from a list with 2 int values.
  LineColumn.fromList(List<int> list)
  : line = list[0],
    column = list[1];

  /// The line number.
  int line;
  /// The column number.
  int column;

  @override
  String toString() => '$line:$column';
}