import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

const double epsilon = 1e-10;

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

    test('to_str', () async {
      expect(await exec('<: Core:to_str("abc")'), StrValue('abc'));
      expect(await exec('<: Core:to_str(123)'), StrValue('123'));
      expect(await exec('<: Core:to_str(true)'), StrValue('true'));
      expect(await exec('<: Core:to_str(false)'), StrValue('false'));
      expect(await exec('<: Core:to_str(null)'), StrValue('null'));
      expect(await exec('<: Core:to_str({ a: "abc", b: 1234 })'), StrValue('{ a: "abc", b: 1234 }'));
      expect(await exec('<: Core:to_str([ true, "abc", 123, null ])'), StrValue('[ true, "abc", 123, null ]'));
      expect(await exec('<: Core:to_str(@( a, b, c ) {})'), StrValue('@( a, b, c ) { ... }'));
      expect(await exec('''
        let arr = []
        arr.push(arr)
        <: Core:to_str(arr)
      '''), StrValue('[ ... ]'));
      expect(await exec('''
        let arr = []
        arr.push({ value: arr })
        <: Core:to_str(arr)
      '''), StrValue('[ { value: ... } ]'));
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

    test('acosh', () async {
      expect(await exec('<: Math:acosh(2.5)'), HasValue(closeTo(1.566799236972411, epsilon)));
      expect(await exec('<: Math:acosh(0.999999999999)'), HasValue(isNaN));
    });

    test('asinh', () async {
      expect(await exec('<: Math:asinh(2)'), HasValue(closeTo(1.4436354751788103, epsilon)));
    });

    test('atanh', () async {
      expect(await exec('<: Math:atanh(0.5)'), HasValue(closeTo(0.549306144334055, epsilon)));
    });

    test('cbrt', () async {
      expect(await exec('<: Math:cbrt(117649)'), NumValue(49));
    });

    test('clz32', () async {
      expect(await exec('<: Math:clz32(4660)'), NumValue(19));
    });

    test('cosh', () async {
      expect(await exec('<: Math:cosh(2)'), HasValue(closeTo(3.7621956910836314, epsilon)));
    });

    test('exp', () async {
      expect(await exec('<: Math:exp(2)'), HasValue(closeTo(7.38905609893065, epsilon)));
    });

    test('expm1', () async {
      expect(await exec('<: Math:expm1(2)'), HasValue(closeTo(6.38905609893065, epsilon)));
    });

    test('fround', () async {
      expect(await exec('<: Math:fround(1.337)'), NumValue(1.3370000123977661));
    });

    test('hypot', () async {
      expect(await exec('<: Math:hypot([3, 4, 5])'), HasValue(closeTo(7.0710678118654755, epsilon)));
    });

    test('imul', () async {
      expect(await exec('<: Math:imul(4294967294, 5)'), NumValue(-10));
    });

    test('log', () async {
      expect(await exec('<: Math:log(2)'), HasValue(closeTo(0.6931471805599453, epsilon)));
    });

    test('log1p', () async {
      expect(await exec('<: Math:log1p(1)'), HasValue(closeTo(0.6931471805599453, epsilon)));
    });

    test('log10', () async {
      expect(await exec('<: Math:log10(100000)'), NumValue(5));
    });

    test('log2', () async {
      expect(await exec('<: Math:log2(2)'), NumValue(1));
    });

    test('sinh', () async {
      expect(await exec('<: Math:sinh(2)'), HasValue(closeTo(3.626860407847019, epsilon)));
    });

    test('sqrt', () async {
      expect(await exec('<: Math:sqrt(64)'), NumValue(8));
      expect(() async => await exec('<: Math:sqrt(-1)'), throwsA(TypeMatcher<RuntimeError>()));
    });

    test('tanh', () async {
      expect(await exec('<: Math:tanh(1)'), HasValue(closeTo(0.7615941559557649, epsilon)));
    });

    test('trunc', () async {
      expect(await exec('<: Math:trunc(13.37)'), NumValue(13));
    });

    test('trunc', () async {
      expect(await exec('<: Math:trunc(13.37)'), NumValue(13));
      expect(await exec('<: Math:trunc(-42.84)'), NumValue(-42));
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
      final res = await exec('''
        @test(seed) {
          let random = Math:gen_rng(seed)
          return random(0 100)
        }
        let seed1 = "hoge"
        let seed2 = 123
        let test1 = test(seed1) == test(seed1)
        let test2 = test(seed1) == test(seed2)
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

    test('from_codepoint', () async {
      final res = await exec('''
        <: Str:from_codepoint(65)
      ''');
      expect(res, StrValue('A'));
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

    test('parsable', () async {
      expect(await exec('<: Json:parsable("{ \\"abc\\": 123 }")'), BoolValue(true));
      expect(await exec('<: Json:parsable("hoge")'), BoolValue(false));
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
      ''');

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
      ''');

      int duration = DateTime.now().millisecondsSinceEpoch - prevTime;
      expect(res, BoolValue(true));
      expect(duration, greaterThanOrEqualTo(1500));
    });
  });
}