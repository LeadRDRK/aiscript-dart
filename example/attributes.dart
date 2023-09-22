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

  // Create the interpreter state
  final state = Interpreter({});
  state.source = res.source;
  // Create our own scope that inherits from the root scope so we can access the variables later
  final scope = Scope.child(state.scope);
  // Execute the script in the custom scope using a custom context
  // Alternatively, you could also use [state.scope] directly, which would define the variables
  // in the root scope.
  await state.exec(res.ast, Context(scope));

  // Get the values from the scope
  // The Value classes are JSON serializable so no need for any extra processing
  final Map<String, Value> json = {};
  scope.forEach((name, value) {
    final attributes = value.attributes;
    if (attributes == null || attributes.isEmpty) return;

    var serializable = false;
    var key = name; // Default to variable name

    for (final attr in attributes) {
      switch (attr.name) {
        case 'Serializable':
          serializable = true;
          break;

        case 'Key': {
          // Assume that it's a string value
          // You might want to handle invalid values in your actual code
          key = attr.value.cast<StrValue>().value;
          break;
        }
      }
    }

    if (serializable) json[key] = value;
  });

  // Encode and print the result
  print(jsonEncode(json));
}