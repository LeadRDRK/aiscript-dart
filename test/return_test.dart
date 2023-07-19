import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('Early return', () async {
    final res = await exec('''
      @f() {
        if true {
          return "ai"
        }

        "pope"
      }
      <: f()
    ''');
    expect(res, StrValue('ai'));
  });

  test('Early return (nested)', () async {
    final res = await exec('''
      @f() {
        if true {
          if true {
            return "ai"
          }
        }

        "pope"
      }
      <: f()
    ''');
    expect(res, StrValue('ai'));
  });

  test('Early return (nested) 2', () async {
    final res = await exec('''
      @f() {
        if true {
          return "ai"
        }

        "pope"
      }

      @g() {
        if (f() == "ai") {
          return "kawaii"
        }

        "pope"
      }

      <: g()
    ''');
    expect(res, StrValue('kawaii'));
  });

  test('Early return without block', () async {
    final res = await exec('''
      @f() {
        if true return "ai"

        "pope"
      }
      <: f()
    ''');
    expect(res, StrValue('ai'));
  });

  test('return inside for', () async {
    final res = await exec('''
    @f() {
      var count = 0
      for (let i, 100) {
        count += 1
        if (i == 42) {
          return count
        }
      }
    }
    <: f()
    ''');
    expect(res, NumValue(43));
  });

  test('return inside for 2', () async {
    final res = await exec('''
      @f() {
        for (let i, 10) {
          return 1
        }
        2
      }
      <: f()
    ''');
    expect(res, NumValue(1));
  });

  test('return inside loop', () async {
    final res = await exec('''
      @f() {
        var count = 0
        loop {
          count += 1
          if (count == 42) {
            return count
          }
        }
      }
      <: f()
    ''');
    expect(res, NumValue(42));
  });

  test('return inside loop 2', () async {
    final res = await exec('''
      @f() {
        loop {
          return 1
        }
        2
      }
      <: f()
    ''');
    expect(res, NumValue(1));
  });

  test('return inside each', () async {
    final res = await exec('''
      @f() {
        var count = 0
        each (let item, ["ai", "chan", "kawaii"]) {
          count += 1
          if (item == "chan") {
                  return count
          }
        }
      }
      <: f()
    ''');
    expect(res, NumValue(2));
  });

  test('return inside each 2', () async {
    final res = await exec('''
      @f() {
        each (let item, ["ai", "chan", "kawaii"]) {
          return 1
        }
        2
      }
      <: f()
    ''');
    expect(res, NumValue(1));
  });
}