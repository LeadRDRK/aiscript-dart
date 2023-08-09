# AiScript for Dart

[![pub.dev](https://img.shields.io/pub/v/aiscript.svg)](https://pub.dev/packages/aiscript)
[![build](https://github.com/LeadRDRK/aiscript-dart/actions/workflows/dart.yml/badge.svg)](https://github.com/LeadRDRK/aiscript-dart/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/LeadRDRK/aiscript-dart/branch/main/graph/badge.svg?token=DPVQPA9XOB)](https://codecov.io/gh/LeadRDRK/aiscript-dart)

AiScript parser and interpreter for Dart. Based on the reference implementation ([syuilo/aiscript](https://github.com/syuilo/aiscript)). This library has a very similar API to the original.

AiScript is a lightweight scripting language that was designed to run on top of JavaScript. For more information, check out the original repo's [Getting started guide](https://github.com/syuilo/aiscript/blob/master/docs/get-started.md) ([en](https://github.com/syuilo/aiscript/blob/master/translations/en/docs/get-started.md))

This package also contains a command line REPL program in `bin/repl.dart`

### Implementation details
- `Core:v` will correspond to the latest AiScript version that this is compatible with (not the library's actual version).
- **Currently fully compatible with:** AiScript v0.15.0
- Mostly acts the same as the original implementation. If you find any differences, please report it as a bug (unless explicitly specified below).
- Similar to the original, the API of this library is still unstable. Please be careful when upgrading to a new minor version (e.g. 0.1.0 -> 0.2.0) as breaking API changes might be present.

### Non-standard behaviors
- Out of range array assignments are allowed for now. Empty spots will be filled with null values.
- Null safety: All functions must return a Value object. If a function doesn't need to return a value, it must still return a NullValue object.
- Number values are passed to functions as a copy. Other types of values are marked as final and cannot be changed once initialized.
- Async functions (timeout, interval) will not run the timers on their own due to how Dart works. You must await for `Interpreter.runTimers()` after `Interpreter.exec()` has finished so that the timers would run.

# API reference
[View on pub.dev](https://pub.dev/documentation/aiscript/latest/)

# Examples
See [`/example`](https://github.com/LeadRDRK/aiscript-dart/tree/main/example) for more examples.
```dart
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
  await state.exec(res.ast); // Output: Hello world!
}
```
# License
[MIT](LICENSE)

This project's test suite contains code from [syuilo/aiscript](https://github.com/syuilo/aiscript) which also uses the same license.