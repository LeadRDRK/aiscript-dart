import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('basic', () async {
    final res = await exec('''
      let str = "kawaii"
      <: `Ai is {str}!`
    ''');
    expect(res, StrValue('Ai is kawaii!'));
  });

  test('convert to str', () async {
    final res = await exec('''
      <: `1 + 1 = {(1 + 1)}`
    ''');
    expect(res, StrValue('1 + 1 = 2'));
  });

  test('invalid', () async {
    expect(() async => await exec('<: `{hoge}`'), throwsA(TypeMatcher<RuntimeError>()));
  });

  test('escape', () async {
    final res = await exec('''
      let message = "Hello"
      <: `\\`a\\{b\\}c\\``
    ''');
    expect(res, StrValue('`a{b}c`'));
  });

  test('array', () async {
    final res = await exec('''
      let arr = [1, 2, 3]
      <: `a{arr}b`
    ''');
    expect(res, StrValue('a[ 1, 2, 3 ]b'));
  });
}