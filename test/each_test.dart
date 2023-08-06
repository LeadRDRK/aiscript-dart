import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('standard', () async {
    final res = await exec('''
      let msgs = []
      each let item, ["ai", "chan", "kawaii"] {
        msgs.push([item, "!"].join())
      }
      <: msgs
    ''');
    expect(res, HasValue([StrValue('ai!'), StrValue('chan!'), StrValue('kawaii!')]));
  });

  test('break', () async {
    final res = await exec('''
      let msgs = []
      each let item, ["ai", "chan", "kawaii" "yo"] {
        if (item == "kawaii") break
        msgs.push([item, "!"].join())
      }
      <: msgs
    ''');
    expect(res, HasValue([StrValue('ai!'), StrValue('chan!')]));
  });

  test('single statement', () async {
    final res = await exec('''
      let msgs = []
      each let item, ["ai", "chan", "kawaii"] msgs.push([item, "!"].join())
      <: msgs
    ''');
    expect(res, HasValue([StrValue('ai!'), StrValue('chan!'), StrValue('kawaii!')]));
  });

  test('var name without space', () {
    expect(() async =>
      await exec('''
        each letitem, ["ai", "chan", "kawaii"] {
          <: item
        }
      '''),
      throwsA(TypeMatcher<SyntaxError>())
    );
  });
}