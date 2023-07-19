class LineColumn {
  LineColumn(this.line, this.column);
  LineColumn.fromList(List<int> list)
  : line = list[0],
    column = list[1];

  int line;
  int column;

  @override
  String toString() => '$line:$column';
}