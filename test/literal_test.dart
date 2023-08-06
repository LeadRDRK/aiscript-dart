import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('string (single quote)', () async {
    final res = await exec('''
      <: 'foo'
    ''');
    expect(res, StrValue('foo'));
  });

  test('string (double quote)', () async {
    final res = await exec('''
      <: "foo"
    ''');
    expect(res, StrValue('foo'));
  });

  test('Escaped double quote', () async {
    final res = await exec('<: "ai saw a note \\"bebeyo\\"."');
    expect(res, StrValue('ai saw a note "bebeyo".'));
  });

  test('Escaped single quote', () async {
    final res = await exec('<: \'ai saw a note \\\'bebeyo\\\'.\'');
    expect(res, StrValue('ai saw a note \'bebeyo\'.'));
  });

  test('bool (true)', () async {
    final res = await exec('''
      <: true
    ''');
    expect(res, BoolValue(true));
  });

  test('bool (false)', () async {
    final res = await exec('''
      <: false
    ''');
    expect(res, BoolValue(false));
  });

  test('number (Int)', () async {
    final res = await exec('''
      <: 10
    ''');
    expect(res, NumValue(10));
  });

  test('number (Float)', () async {
    final res = await exec('''
      <: 0.5
    ''');
    expect(res, NumValue(0.5));
  });

  test('arr (separated by comma)', () async {
    final res = await exec('''
      <: [1, 2, 3]
    ''');
    expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3)]));
  });

  test('arr (separated by comma) (with trailing comma)', () async {
    final res = await exec('''
      <: [1, 2, 3,]
    ''');
    expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3)]));
  });

  test('arr (separated by line break)', () async {
    final res = await exec('''
      <: [
        1
        2
        3
      ]
    ''');
    expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3)]));
  });

  test('arr (separated by line break and comma)', () async {
    final res = await exec('''
      <: [
        1,
        2,
        3
      ]
    ''');
    expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3)]));
  });

  test('arr (separated by line break and comma) (with trailing comma)', () async {
    final res = await exec('''
      <: [
        1,
        2,
        3,
      ]
    ''');
    expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3)]));
  });

  test('obj (separated by comma)', () async {
    final res = await exec('''
      <: { a: 1, b: 2, c: 3 }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj (separated by comma) (with trailing comma)', () async {
    final res = await exec('''
      <: { a: 1, b: 2, c: 3, }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj (separated by semicolon)', () async {
    final res = await exec('''
      <: { a: 1; b: 2; c: 3 }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj (separated by semicolon) (with trailing semicolon)', () async {
    final res = await exec('''
      <: { a: 1; b: 2; c: 3; }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj (separated by line break)', () async {
    final res = await exec('''
      <: {
        a: 1
        b: 2
        c: 3
      }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj (separated by line break and semicolon)', () async {
    final res = await exec('''
      <: {
        a: 1;
        b: 2;
        c: 3
      }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj (separated by line break and semicolon) (with trailing semicolon)', () async {
    final res = await exec('''
      <: {
        a: 1;
        b: 2;
        c: 3;
      }
    ''');
    expect(res, HasValue({'a': NumValue(1), 'b': NumValue(2), 'c': NumValue(3)}));
  });

  test('obj and arr (separated by line break)', () async {
    final res = await exec('''
      <: {
        a: 1
        b: [
          1
          2
          3
        ]
        c: 3
      }
    ''');
    expect(res, HasValue({
      'a': NumValue(1),
      'b': HasValue([NumValue(1), NumValue(2), NumValue(3)]),
      'c': NumValue(3)
    }));
  });
}