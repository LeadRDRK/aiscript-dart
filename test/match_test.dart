import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('Basic', () async {
    final res = await exec('''
      <: match 2 {
        1 => "a"
        2 => "b"
        3 => "c"
      }
    ''');
    expect(res, StrValue('b'));
  });

  test('When default not provided, returns null', () async {
    final res = await exec('''
      <: match 42 {
        1 => "a"
        2 => "b"
        3 => "c"
      }
    ''');
    expect(res, NullValue());
  });

  test('With default', () async {
    final res = await exec('''
      <: match 42 {
        1 => "a"
        2 => "b"
        3 => "c"
        * => "d"
    }
    ''');
    expect(res, StrValue('d'));
  });

  test('With block', () async {
    final res = await exec('''
      <: match 2 {
        1 => 1
        2 => {
          let a = 1
          let b = 2
          (a + b)
        }
        3 => 3
      }
    ''');
    expect(res, NumValue(3));
  });

  test('With return', () async {
    final res = await exec('''
      @f(x) {
        match x {
          1 => {
            return "ai"
          }
        }
        "foo"
      }
      <: f(1)
    ''');
    expect(res, StrValue('ai'));
  });
}