import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('def', () async {
    final res = await exec('''
      let abc: num = 1
      var xyz: str = "abc"
      <: [abc xyz]
    ''');
    expect(res, HasValue([NumValue(1), StrValue('abc')]));
  });

  test('fn def', () async {
    final res = await exec('''
      @f(x: arr<num>, y: str, z: @(num) => bool): arr<num> {
        x[3] = 0
        y = "abc"
        var r: bool = z(x[0])
        x[4] = if r 5 else 10
        x
      }

      <: f([1, 2, 3], "a", @(n) { n == 1 })
    ''');
    expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3), NumValue(0), NumValue(5)]));
  });

}