///
/// File: example/attributes.dart
/// This example shows you how to work with variable attributes.
/// 
/// We will be serializing variables marked with the "Serializable" attribute to a JSON object.
/// The "Key" attribute can be used to customize the value's key in the object.
///

import 'dart:convert';

import 'package:aiscript/aiscript.dart';

void main() async {
  // Create the parser
  final parser = Parser();

  // Parse the script
  final ParseResult res = parser.parse('''
#[Serializable]
let a = 123

#[Serializable]
let b = 12 + 34

let notSerialized = 456

#[Serializable]
#[Key "foobar"]
let foo = "bar"
''');

  // Traverse the syntax tree to find the serializable variable definition nodes
  final nodes = res.ast;
  final Map<String, String> serializableVars = {};
  for (final node in nodes) {
    // Check node type and see if it has any attributes
    if (node is! DefinitionNode || node.attr.isEmpty) continue;

    var serializable = false;
    var key = node.name; // Default to variable name

    for (final attr in node.attr) {
      switch (attr.name) {
        case 'Serializable':
          serializable = true;
          break;

        case 'Key': {
          final strNode = attr.value;
          if (strNode is! StrNode) throw RuntimeError('Invalid Key attribute');
          key = strNode.value;
          break;
        }
      }
    }

    if (serializable) {
      // Store variable name so we could get its value later
      serializableVars[key] = node.name;
    }
  }

  // Create the interpreter state and execute the script to evaluate the values
  final state = Interpreter({});
  state.source = res.source;
  await state.exec(nodes);

  // Get the values from the global scope
  // The Value classes are JSON serializable so no need for any extra processing
  final scope = state.scope;
  final Map<String, Value> json = {};
  serializableVars.forEach((key, varName) {
    json[key] = scope[varName];
  });

  // Encode and print the result
  print(jsonEncode(json));
}