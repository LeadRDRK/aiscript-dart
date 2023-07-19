import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('single line comment', () async {
    final res = await exec('''
      // let a = ...
      let a = 42
      <: a
    ''');
    expect(res, NumValue(42));
  });

  test('multi line comment', () async {
    final res = await exec('''
      /* variable declaration here...
        let a = ...
      */
      let a = 42
      <: a
    ''');
    expect(res, NumValue(42));
  });

  test('multi line comment 2', () async {
    final res = await exec('''
      /* variable declaration here...
        let a = ...
      */
      let a = 42
      /*
        another comment here
      */
      <: a
    ''');
    expect(res, NumValue(42));
  });

  test('// as string', () async {
    final res = await exec('<: "//"');
    expect(res, StrValue('//'));
  });
}