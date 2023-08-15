import 'dart:async';
import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';

Future<Value> exec(String program, {Map<String, Value>? vars}) async {
  final completer = Completer<Value>();

  final parser = Parser();
  final res = parser.parse(program);

  final state = Interpreter(vars ?? {},
    printFn: (v) => completer.complete(v),
    maxStep: 9999
  );
  state.source = res.source;
  state.exec(res.ast).catchError((error) {
    completer.completeError(error);
    return NullValue();
  });

  return completer.future;
}

Map<String, dynamic> getMeta(String program) {
  final parser = Parser();
  final res = parser.parse(program);

  return Interpreter.collectMetadata(res.ast);
}

class HasValue extends CustomMatcher {
  HasValue(Object? valueOrMatcher) : super('a Value object with value', 'value field', valueOrMatcher);

  @override
  Object? featureValueOf(actual) {
    return (actual as PrimitiveValue).value;
  }
}