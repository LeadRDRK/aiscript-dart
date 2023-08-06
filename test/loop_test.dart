import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('basic', () async {
    final res = await exec('''
      var count = 0
      loop {
        if (count == 10) break
        count = (count + 1)
      }
      <: count
    ''');
    expect(res, NumValue(10));
  });

  test('with continue', () async {
    final res = await exec('''
      var a = ["ai" "chan" "kawaii" "yo" "!"]
      var b = []
      loop {
        var x = a.shift()
        if (x == "chan") continue
        if (x == "yo") break
        b.push(x)
      }
      <: b
    ''');
    expect(res, HasValue([StrValue('ai'), StrValue('kawaii')]));
  });
}