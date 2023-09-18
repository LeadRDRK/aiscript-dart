///
/// File: example/modules.dart
/// This example shows you how to use modules.
/// Depends on the modules in the "modules" directory.
///

import 'package:aiscript/aiscript.dart';
import 'package:aiscript/file_module_resolver.dart';

import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  // Create the parser
  final parser = Parser();

  // Parse the script
  final ParseResult res = parser.parse('''
// Check the modules's source code in their respective files.

/*
  File extension is optional if FileModuleResolver.ext
  is set (Default: ".aiscript")
*/
let myModule = require("my_module")
<: `myValue: {myModule.value}`
myModule.func()

/*
  Requiring a module twice will not rerun it
  (module has been required from within my_module)
*/
let pi = require("math/pi.aiscript")
<: `Pi: {pi}`
''');

  // Create the interpreter state with the module resolver
  final state = Interpreter({},
    printFn: print,
    moduleResolver: FileModuleResolver(
      // Use the same parser we created earlier.
      // A module resolver can be implemented without a parser,
      // so any resolver that wants to use one must have its own parser.
      parser,

      // Modules will be loaded from <script dir>/modules
      // By default this is set to ['']
      paths: [p.join(p.dirname(Platform.script.path), 'modules')],

      // (Optional) You can enable sanitizePaths to disallow
      // absolute paths and relative paths that contains "/.."
      sanitizePaths: true
    )
  );

  // Finally, execute the script
  state.source = res.source;
  await state.exec(res.ast);

  /*
    Expected output:

    /path/to/example/modules/my_module.aiscript
    /path/to/example/modules/math/pi.aiscript
    myValue: 21
    myFunc - Pi: 3.14
    Pi: 3.14

    The modules were made to print their path when they're executed (__module.path).

    Since they're only executed once when they're first required,
    you only see their paths once, despite "math/pi" being required twice
    in the same state.
  */
}