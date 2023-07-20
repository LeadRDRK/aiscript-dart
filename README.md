# AiScript for Dart
AiScript parser and interpreter for Dart. Based on the reference implementation ([syuilo/aiscript](https://github.com/syuilo/aiscript)). This library has a very similar API to the original.

AiScript is a lightweight scripting language that was designed to run on top of JavaScript. For more information, check out the original repo's [Getting started guide](https://github.com/syuilo/aiscript/blob/master/docs/get-started.md) ([en](https://github.com/syuilo/aiscript/blob/master/translations/en/docs/get-started.md))

This package also contains a command line REPL program in `bin/repl.dart`

### Implementation details
- `Core:v` will correspond to the latest AiScript version that this is compatible with (not the library's actual version).
- Mostly acts the same as the original implementation. If you find any differences, please report it as a bug (unless explicitly specified below).

### Non-standard behaviors
- Out of range array assignments are allowed for now. Empty spots will be filled with null values.
- Null safety: All functions must return a Value object. If a function doesn't need to return a value, it must still return a NullValue object.

# API reference
[View on pub.dev](https://pub.dev/documentation/aiscript/latest/)

# Examples
See [`/example`](https://github.com/LeadRDRK/aiscript-dart/tree/main/example)

# License
[MIT](LICENSE)

This project's test suite contains code from [syuilo/aiscript](https://github.com/syuilo/aiscript) which also uses the same license.