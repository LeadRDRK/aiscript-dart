import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('==', () async {
    expect(await exec('<: 1 == 1'), BoolValue(true));
    expect(await exec('<: 1 == 2'), BoolValue(false));
  });

  test('!=', () async {
    expect(await exec('<: 1 != 2'), BoolValue(true));
    expect(await exec('<: 1 != 1'), BoolValue(false));
  });

  test('&&', () async {
    expect(await exec('<: true && true'), BoolValue(true));
    expect(await exec('<: true && false'), BoolValue(false));
    expect(await exec('<: false && true'), BoolValue(false));
    expect(await exec('<: false && false'), BoolValue(false));
    expect(await exec('<: false && null'), BoolValue(false));
    expect(() async => await exec('<: true && null'), throwsA(TypeMatcher<TypeError>()));
    expect(
      await exec('''
        var tmp = null
        @func() {
          tmp = true
          return true
        }
        false && func()
        <: tmp
      '''),
      NullValue()
    );
    expect(
      await exec('''
        var tmp = null
        @func() {
          tmp = true
          return true
        }
        true && func()
        <: tmp
      '''),
      BoolValue(true)
    );
  });

  test('||', () async {
    expect(await exec('<: true || true'), BoolValue(true));
    expect(await exec('<: true || false'), BoolValue(true));
    expect(await exec('<: false || true'), BoolValue(true));
    expect(await exec('<: false || false'), BoolValue(false));
    expect(await exec('<: true || null'), BoolValue(true));
    expect(() async => await exec('<: false || null'), throwsA(TypeMatcher<TypeError>()));
    expect(
      await exec('''
        var tmp = null
        @func() {
          tmp = true
          return true
        }
        true || func()
        <: tmp
      '''),
      NullValue()
    );
    expect(
      await exec('''
        var tmp = null
        @func() {
          tmp = true
          return true
        }
        false || func()
        <: tmp
      '''),
      BoolValue(true)
    );
  });

  test('+', () async {
    expect(await exec('<: 1 + 2'), NumValue(3));
  });

  test('-', () async {
    expect(await exec('<: 2 - 1'), NumValue(1));
  });

  test('*', () async {
    expect(await exec('<: 1 * 2'), NumValue(2));
  });

  test('^', () async {
    expect(await exec('<: (1 ^ 0)'), NumValue(1));
  });

  test('/', () async {
    expect(await exec('<: (1 / 1)'), NumValue(1));
  });

  test('%', () async {
    expect(await exec('<: (1 % 1)'), NumValue(0));
  });

  test('>', () async {
    expect(await exec('<: (2 > 1)'), BoolValue(true));
    expect(await exec('<: (1 > 1)'), BoolValue(false));
    expect(await exec('<: (0 > 1)'), BoolValue(false));
  });

  test('<', () async {
    expect(await exec('<: (2 < 1)'), BoolValue(false));
    expect(await exec('<: (1 < 1)'), BoolValue(false));
    expect(await exec('<: (0 < 1)'), BoolValue(true));
  });

  test('>=', () async {
    expect(await exec('<: (2 >= 1)'), BoolValue(true));
    expect(await exec('<: (1 >= 1)'), BoolValue(true));
    expect(await exec('<: (0 >= 1)'), BoolValue(false));
  });

  test('<=', () async {
    expect(await exec('<: (2 <= 1)'), BoolValue(false));
    expect(await exec('<: (1 <= 1)'), BoolValue(true));
    expect(await exec('<: (0 <= 1)'), BoolValue(true));
  });

  test('precedence', () async {
    expect(await exec('<: 1 + 2 * 3 + 4'), NumValue(11));
    expect(await exec('<: 1 + 4 / 4 + 1'), NumValue(3));
    expect(await exec('<: 1 + 1 == 2 && 2 * 2 == 4'), BoolValue(true));
    expect(await exec('<: (1 + 1) * 2'), NumValue(4));
  });

  test('negative numbers', () async {
    expect(await exec('<: 1+-1'), NumValue(0));
    expect(await exec('<: 1--1'), NumValue(2));               
    expect(await exec('<: -1*-1'), NumValue(1));
    expect(await exec('<: -1==-1'), BoolValue(true));
    expect(await exec('<: 1>-1'), BoolValue(true));
    expect(await exec('<: -1<1'), BoolValue(true));
  });

  test('parentheses', () async {
    expect(await exec('<: (1 + 10) * (2 + 5)'), NumValue(77));
  });

  test('divide by zero', () {
    expect(() async => await exec('<: (0 / 0)'), throwsA(TypeMatcher<RuntimeError>()));
  });

  test('syntax symbols vs infix operators', () async {
    final res = await exec('''
      <: match true {
          1 == 1 => "true"
          1 < 1 => "false"
    }
    ''');
    expect(res, StrValue('true'));
  });

  test('number + if expression', () async {
    expect(await exec('<: 1 + if true 1 else 2'), NumValue(2));
  });

  test('number + match expression', () async {
    final res = await exec('''
      <: 1 + match 2 == 2 {
          true => 3
          false => 4
    }
    ''');
    expect(res, NumValue(4));
  });

  test('eval + eval', () async {
    expect(await exec('<: eval { 1 } + eval { 1 }'), NumValue(2));
  });

  test('disallow line break', () {
    expect(
      () async => await exec('''
        <: 1 +
        1 + 1
      '''),
      throwsA(TypeMatcher<SyntaxError>())
    );
  });

  test('escaped line break', () async {
    expect(
      await exec('''
        <: 1 + \\
        1 + 1
      '''),
      NumValue(3)
    );
  });
}