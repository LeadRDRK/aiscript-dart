///
/// File: example/custom_vars.dart
/// This example shows you how to create custom variables and initialize the interpreter state with them.
///

import 'package:aiscript/aiscript.dart';

final Map<String, Value> customVars = {
  // Define a variable using Value objects (StrValue, NumValue, etc.)
  'myVar': StrValue('Hello world!'),

  // Define native functions using NativeFnValue
  'myFunction': NativeFnValue((_, __) async { // Function needs to return a Future
    print('Hello from Dart!');

    // Functions that do not return anything must return a NullValue explicitly
    return NullValue();
  }),

  // Define variables inside a namespace by simply adding 'namespace:' before the variable name
  'myNs:function': NativeFnValue((args, state) async {
    // Check the type of the argument and get its Value object
    // This will throw a TypeError if the value isn't the expected type
    final str = args.check<StrValue>(0);

    print('Function called from $str!');

    // Return value
    return NumValue(123);
  }),
};

void main() async {
  final parser = Parser();
  final ParseResult res = parser.parse('''
<: myVar
myFunction()
myNs:function('AiScript')
''');

  // Create the interpreter state with custom vars
  final state = Interpreter(customVars, printFn: print);
  state.source = res.source;

  // Execute the script and print the returned value
  final value = await state.exec(res.ast);
  print('Value: $value');
}