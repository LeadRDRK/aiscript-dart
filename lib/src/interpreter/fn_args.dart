import 'dart:collection';
import 'value.dart';
import '../core/error.dart';

class FnArgs extends ListBase<Value> {
  final List<Value> _l;
  const FnArgs(this._l);

  T check<T extends Value>(int i) {
    assert(T != Never);
    final v = _l.elementAtOrNull(i);
    if (v is T) {
      return v;
    }
    else {
      throw TypeError('invalid argument #${i + 1} (expected ${T.toString()}, got ${v != null ? v.runtimeType : 'nothing'})');
    }
  }

  @override
  set length(int newLength) { _l.length = newLength; }

  @override
  int get length => _l.length;

  @override
  Value operator [](int index) => _l[index];

  @override
  void operator []=(int index, Value value) => _l[index] = value;

  @override
  void add(Value element) => _l.add(element);

  @override
  void addAll(Iterable<Value> iterable) => _l.addAll(iterable);
}