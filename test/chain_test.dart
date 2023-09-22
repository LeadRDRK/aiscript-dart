import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('chain access (prop + index + call)', () async {
    final res = await exec('''
      let obj = {
        a: {
          b: [@(name) { name }, @(str) { "chan" }, @() { "kawaii" }];
        };
      }

      <: obj.a.b[0]("ai")
    ''');
    expect(res, StrValue('ai'));
  });

  test('chained assign left side (prop + index)', () async {
    final res = await exec('''
      let obj = {
        a: {
          b: ["ai", "chan", "kawaii"];
        };
      }

      obj.a.b[1] = "taso"

      <: obj
    ''');
    expect(res, HasValue({
      'a': HasValue({
        'b': HasValue([StrValue('ai'), StrValue('taso'), StrValue('kawaii')])
      })
    }));
  });

  test('chained assign right side (prop + index + call)', () async {
    final res = await exec('''
      let obj = {
        a: {
          b: ["ai", "chan", "kawaii"];
        };
      }

      var x = null
      x = obj.a.b[1]

      <: x
    ''');
    expect(res, StrValue('chan'));
  });

  test('chained inc/dec left side (index + prop)', () async {
    final res = await exec('''
      let arr = [
        {
          a: 1;
          b: 2;
        }
      ]

      arr[0].a += 1
      arr[0].b -= 1

      <: arr
    ''');
    expect(res, HasValue([
      HasValue({
        'a': NumValue(2),
        'b': NumValue(1)
       })
    ]));
  });

  test('chained inc/dec left side (prop + index)', () async {
    final res = await exec('''
      let obj = {
        a: {
          b: [1, 2, 3];
        };
      }

      obj.a.b[1] += 1
      obj.a.b[2] -= 1

      <: obj
    ''');
    expect(res, HasValue({
      'a': HasValue({
        'b': HasValue([NumValue(1), NumValue(3), NumValue(2)])
      })
    }));
  });

  test('prop in def', () async {
    final res = await exec('''
      let x = @() {
        let obj = {
          a: 1
        }
        obj.a
      }

      <: x()
    ''');
    expect(res, NumValue(1));
  });

  test('prop in return', () async {
    final res = await exec('''
      let x = @() {
        let obj = {
          a: 1
        }
        return obj.a
        2
      }

      <: x()
    ''');
    expect(res, NumValue(1));
  });

  test('prop in each', () async {
    final res = await exec('''
      let msgs = []
      let x = { a: ["ai", "chan", "kawaii"] }
      each let item, x.a {
        let y = { a: item }
        msgs.push([y.a, "!"].join())
      }
      <: msgs
    ''');
    expect(res, HasValue([StrValue('ai!'), StrValue('chan!'), StrValue('kawaii!')]));
  });

  test('prop in for', () async {
    final res = await exec('''
      let x = { times: 10, count: 0 }
      for (let i, x.times) {
        x.count = (x.count + i)
      }
      <: x.count
    ''');
    expect(res, NumValue(45));
  });

  test('object with index', () async {
    final res = await exec('''
      let ai = {a: {}}['a']
      ai['chan'] = 'kawaii'
      <: ai[{a: 'chan'}['a']]
    ''');
    expect(res, StrValue('kawaii'));
  });
}