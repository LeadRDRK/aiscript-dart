import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';

void main() {
  test('single attribute with function (str)', () async {
    final parser = Parser();
    final nodes = parser.parse('''
      #[Event "Received"]
      @onReceived(data) {
        data
      }
    ''').ast;

    expect(nodes.length, 1);
    final node = nodes[0] as DefinitionNode;
    expect(node.name, 'onReceived');
    expect(node.attr.length, 1);

    final attr = node.attr[0];
    expect(attr.name, 'Event');
    final strNode = attr.value as StrNode;
    expect(strNode.value, 'Received');
  });

  test('multiple attributes with function (obj, str, bool)', () async {
    final parser = Parser();
    final nodes = parser.parse('''
      #[Endpoint { path: "/notes/create"; }]
      #[Desc "Create a note."]
      #[Cat true]
      @createNote(text) {
        <: text
      }
    ''').ast;

    expect(nodes.length, 1);
    final node = nodes[0] as DefinitionNode;
    expect(node.name, 'createNote');
    expect(node.attr.length, 3);

    final endpoint = node.attr[0];
    expect(endpoint.name, 'Endpoint');
    final objNode = endpoint.value as ObjNode;
    final pathNode = objNode.value['path'] as StrNode;
    expect(pathNode.value, '/notes/create');

    final desc = node.attr[1];
    expect(desc.name, 'Desc');
    final strNode = desc.value as StrNode;
    expect(strNode.value, 'Create a note.');

    final cat = node.attr[2];
    expect(cat.name, 'Cat');
    final boolNode = cat.value as BoolNode;
    expect(boolNode.value, true);
  });

  test('single attribute (no value)', () async {
    final parser = Parser();
    final nodes = parser.parse('''
      #[serializable]
      let data = 1
    ''').ast;

    expect(nodes.length, 1);
    final node = nodes[0] as DefinitionNode;
    expect(node.name, 'data');
    expect(node.attr.length, 1);

    final attr = node.attr[0];
    expect(attr.name, 'serializable');
    final boolNode = attr.value as BoolNode;
    expect(boolNode.value, true);
  });
}