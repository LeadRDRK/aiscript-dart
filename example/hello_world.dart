///
/// File: example/hello_world.dart
/// This example shows you how to parse a script and run it.
///

import 'package:aiscript/aiscript.dart';

void main() async {
  // Create the parser
  final parser = Parser();

  // Parse the script
  final ParseResult res = parser.parse('<: "Hello world!"');

  // Create the interpreter state with the print function (optional)
  final state = Interpreter({}, printFn: print);

  // (Optional) Set the preprocessed source of the program
  // This will be used for error messages
  state.source = res.source;

  // Finally, execute the script
  await state.exec(res.ast);
}