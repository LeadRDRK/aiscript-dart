import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('len', () async {
    final res = await exec('''
      <: "👍🏽🍆🌮".len
    ''');
    expect(res, NumValue(3));
  });

  test('pick', () async {
    final res = await exec('''
      <: "👍🏽🍆🌮".pick(1)
    ''');
    expect(res, StrValue('🍆'));
  });

  test('slice', () async {
    final res = await exec('''
      <: "Emojis 👍🏽 are 🍆 poison. 🌮s are bad.".slice(7, 14)
    ''');
    expect(res, StrValue('👍🏽 are 🍆'));
  });

  test('split', () async {
    final res = await exec('''
      <: "👍🏽🍆🌮".split()
    ''');
    expect(res, HasValue([StrValue('👍🏽'), StrValue('🍆'), StrValue('🌮')]));
  });
}