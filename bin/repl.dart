import 'dart:convert';
import 'dart:io';

import 'package:aiscript/aiscript.dart';

final Map<String, Value> vars = {
  'exit': NativeFnValue((_, __) => exit(0))
};

// Regex to match curly brackets
final clRegex = RegExp(r'({+)\s*$');
final crRegex = RegExp(r'^\s*(}+)');

void main() async {
  final parser = Parser();
  final state = Interpreter(vars,
    printFn: print,
    readlineFn: (msg) async {
      stdout.write(msg);
      return stdin.readLineSync(encoding: utf8) ?? '';
    }
  );

  final ver = await state.exec([IdentifierNode(name: 'Core:v')]);
  print('''
AiScript REPL - Core:v = $ver
Type "help" for more information.
''');
  
  while (true) {
    stdout.write('>');

    var script = '';
    int indentLevel = 0;
    while (true) {
      stdout.write('${'...' * indentLevel} ');
      final line = stdin.readLineSync(encoding: utf8);
      if (line == null) {
        print('Failed to read from stdin');
        return;
      }
      script += line;

      var clMatch = clRegex.firstMatch(line);
      if (clMatch != null) {
        indentLevel += clMatch[1]!.length;
      }
      else {
        var crMatch = crRegex.firstMatch(line);
        if (crMatch != null) {
          indentLevel -= crMatch[1]!.length;
        }
      }

      if (indentLevel <= 0) break;
    }

    try {
      ParseResult res = parser.parse(script);
      state.source = res.source;
      print(await state.exec(res.ast));
    }
    catch (e) {
      print(e);
    }
  }
}