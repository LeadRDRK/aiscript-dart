import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  group('Core', () {
    test('range', () async {
      expect(await exec('<: Core:range(1, 10)'), HasValue([
        NumValue(1), NumValue(2), NumValue(3),  NumValue(4), NumValue(5),
        NumValue(6), NumValue(7), NumValue(8), NumValue(9), NumValue(10)
      ]));
      expect(await exec('<: Core:range(1, 1)'), HasValue([NumValue(1)]));
      expect(await exec('<: Core:range(9, 7)'), HasValue([NumValue(9), NumValue(8), NumValue(7)]));
    });

    test('not', () async {
      expect(await exec('<: Core:not(false)'), BoolValue(true));
    });
  });

  group('Math', () {
    test('trig', () async {
      expect(await exec('<: Math:sin(Math:PI / 2)'), NumValue(1));
      expect(await exec('<: Math:sin(0 - (Math:PI / 2))'), NumValue(-1));
      expect(await exec('<: Math:sin(Math:PI / 4) * Math:cos(Math:PI / 4)'), NumValue(0.5));
    });

    test('abs', () async {
      expect(await exec('<: Math:abs(1 - 6)'), NumValue(5));
    });

    test('pow and sqrt', () async {
      expect(await exec('<: Math:sqrt(3^2 + 4^2)'), NumValue(5));
    });

    test('round', () async {
      expect(await exec('<: Math:round(3.14)'), NumValue(3));
      expect(await exec('<: Math:round(-1.414213)'), NumValue(-1));
      expect(await exec('<: Math:round(Math:Infinity / 0)'), NumValue(double.infinity));
    });

    test('ceil', () async {
      expect(await exec('<: Math:ceil(2.71828)'), NumValue(3));
      expect(await exec('<: Math:ceil(0 - Math:PI)'), NumValue(-3));
      expect(await exec('<: Math:ceil(1 / Math:Infinity)'), NumValue(0));
      expect(await exec('<: Math:ceil(Math:Infinity / 0)'), NumValue(double.infinity));
    });

    test('floor', () async {
      expect(await exec('<: Math:floor(23.14069)'), NumValue(23));
      expect(await exec('<: Math:floor(Math:Infinity / 0)'), NumValue(double.infinity));
    });

    test('min', () async {
      expect(await exec('<: Math:min(2, 3)'), NumValue(2));
    });

    test('max', () async {
      expect(await exec('<: Math:max(-2, -3)'), NumValue(-2));
    });

    test('rnd', () async {
      await exec('<: Math:rnd()');
    });

    test('rnd with arg', () async {
      expect(await exec('<: Math:rnd(1, 1.5)'), NumValue(1));
    });

    test('gen_rng', () async {
      // Test will occasionally fail (1 in 10000 chance?)
      // Because it's random.
      final res = await exec('''
        @test(seed) {
          let random = Math:gen_rng(seed)
          return random(0 100)
        }
        let seed1 = `{Util:uuid()}`
        let seed2 = `{Date:year()}`
        let test1 = test(seed1) == test(seed1)
        let test2 = test(seed1) == test(seed2) // fails sometimes
        <: [test1 test2]
      ''');
      expect(res, HasValue([BoolValue(true), BoolValue(false)]));
    });
  });

  group('Obj', () {
    test('keys', () async {
      final res = await exec('''
      let o = { a: 1; b: 2; c: 3; }

      <: Obj:keys(o)
      ''');
      expect(res, HasValue([StrValue('a'), StrValue('b'), StrValue('c')]));
    });

    test('vals', () async {
      final res = await exec('''
      let o = { _nul: null; _num: 24; _str: 'hoge'; _arr: []; _obj: {}; }

      <: Obj:vals(o)
      ''');
      expect(res, HasValue([NullValue(), NumValue(24), StrValue('hoge'), HasValue([]), HasValue({})]));
    });

    test('kvs', () async {
      final res = await exec('''
      let o = { a: 1; b: 2; c: 3; }

      <: Obj:kvs(o)
      ''');
      expect(res, HasValue([
        HasValue([StrValue('a'), NumValue(1)]),
        HasValue([StrValue('b'), NumValue(2)]),
        HasValue([StrValue('c'), NumValue(3)])
      ]));
    });
  });

  group('Str', () {
    test('lf', () async {
			final res = await exec('''
			  <: Str:lf
			''');
			expect(res, StrValue('\n'));
		});
  });

  group('Json', () {
    test('stringify', () async {
			final res = await exec('''
			  <: Json:stringify({
          a: 'hoge'
          b: 21
          c: true
          arr: [1, 2, 3]
          fn: @(){}
        })
			''');
			expect(res, StrValue('{"a":"hoge","b":21,"c":true,"arr":[1,2,3],"fn":"<function>"}'));
		});

    test('parse', () async {
			final res = await exec('''
			  <: Json:parse('{"a":"hoge","b":21,"c":true,"arr":[1,2,3]}')
			''');
			expect(res, HasValue({
        'a': StrValue('hoge'),
        'b': NumValue(21),
        'c': BoolValue(true),
        'arr': HasValue([NumValue(1), NumValue(2), NumValue(3)])
      }));
		});
  });

  test('throw error when required arg missing', () async {
    expect(() async => await exec('<: Core:eq(1)'), throwsA(TypeMatcher<TypeError>()));
  });

  group('Async', () {
    test('timeout', () async {
      var prevTime = DateTime.now().millisecondsSinceEpoch;
      final res = await exec('''
        Async:timeout(1000, @() {
          <: true
        })
      ''', runTimers: true);

      int duration = DateTime.now().millisecondsSinceEpoch - prevTime;
      expect(res, BoolValue(true));
      expect(duration, greaterThanOrEqualTo(1000));
    });

    test('interval', () async {
      var prevTime = DateTime.now().millisecondsSinceEpoch;
      final res = await exec('''
        var count = 0
        let cancel = Async:interval(500, @() {
          count += 1
          if (count == 3) {
            cancel()
            <: true
          }
        })
      ''', runTimers: true);

      int duration = DateTime.now().millisecondsSinceEpoch - prevTime;
      expect(res, BoolValue(true));
      expect(duration, greaterThanOrEqualTo(1500));
    });
  });
}