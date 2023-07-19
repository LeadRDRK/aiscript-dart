import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('empty function', () async {
    final res = await exec('''
      @hoge() { }
      <: hoge()
    ''');
    expect(res, NullValue());
  });

  test('empty lambda', () async {
    final res = await exec('''
      let hoge = @() { }
      <: hoge()
    ''');
    expect(res, NullValue());
  });

  test('lambda that returns an object', () async {
    final res = await exec('''
      let hoge = @() {{}}
      <: hoge()
    ''');
    expect(res, HasValue({}));
  });

  test('closure', () async {
    final res = await exec('''
      @store(v) {
        let state = v
        @() {
          state
        }
      }
      let s = store("ai")
      <: s()
    ''');
    expect(res, StrValue('ai'));
  });

  test('closure (counter)', () async {
    final res = await exec('''
      @create_counter() {
        var count = 0
        {
          get_count: @() { count };
          count: @() { count = (count + 1) };
        }
      }

      let counter = create_counter()
      let get_count = counter.get_count
      let count = counter.count

      count()
      count()
      count()

      <: get_count()
    ''');
    expect(res, NumValue(3));
  });

  test('recursion', () async {
    final res = await exec('''
      @fact(n) {
        if (n == 0) { 1 } else { (fact((n - 1)) * n) }
      }

      <: fact(5)
    ''');
    expect(res, NumValue(120));
  });

  group('call', () {
    test('without args', () async {
      final res = await exec('''
        @f() {
          42
        }
        <: f()
      ''');
      expect(res, NumValue(42));
    });

    test('with args', () async {
      final res = await exec('''
        @f(x) {
          x
        }
        <: f(42)
      ''');
      expect(res, NumValue(42));
    });

    test('with args (separated by comma)', () async {
      final res = await exec('''
        @f(x, y) {
          (x + y)
        }
        <: f(1, 1)
      ''');
      expect(res, NumValue(2));
    });

    test('with args (separated by space)', () async {
      final res = await exec('''
        @f(x y) {
          (x + y)
        }
        <: f(1 1)
      ''');
      expect(res, NumValue(2));
    });

    test('num arg value is copied', () async {
      final res = await exec('''
        var hoge = 1
        @f(value) {
          value += 1
        }
        f(hoge)
        <: hoge
      ''');
      expect(res, NumValue(1));
    });
  });
}