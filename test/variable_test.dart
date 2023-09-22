import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('var', () async {
    final res = await exec('''
      var a = 42
      a = 11
      <: a
    ''');
    expect(res, NumValue(11));
  });

  test('let', () async {
    final res = await exec('''
      let a = 42
      <: a
    ''');
    expect(res, NumValue(42));
  });

  test('let assign', () {
    final ft = exec('''
      let a = 42
      a = 12
    ''');
    expect(() async => await ft, throwsA(TypeMatcher<RuntimeError>()));
  });

  test('add assign', () async {
    final res = await exec('''
      var a = 0
      a += 1
      a += 2
      a += 3
      <: a
    ''');
    expect(res, NumValue(6));
  });

  test('sub assign', () async {
    final res = await exec('''
      var a = 0
      a -= 1
      a -= 2
      a -= 3
      <: a
    ''');
    expect(res, NumValue(-6));
  });

  test('reference not connected', () async {
    final res = await exec('''
      var f = @() { "a" }
      var g = f
      f = @() { "b" }

      <: g()
    ''');
    expect(res, StrValue('a'));
  });

  group('multiple statements in a line', () {
    test('var def', () {
      expect(() async => await exec('let a = 42 let b = 11'), throwsA(TypeMatcher<SyntaxError>()));
    });

    test('var def with operators', () {
      expect(() async => await exec('let a = 13 + 75 let b = 24 + 146'), throwsA(TypeMatcher<SyntaxError>()));
    });
  });

  group('var name starts with reserved word', () {
    test('let', () async {
      final res = await exec('''
        @f() {
          let letcat = "ai"
          letcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('var', () async {
      final res = await exec('''
        @f() {
          let varcat = "ai"
          varcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('return', () async {
      final res = await exec('''
        @f() {
          let returncat = "ai"
          returncat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('each', () async {
      final res = await exec('''
        @f() {
          let eachcat = "ai"
          eachcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('for', () async {
      final res = await exec('''
        @f() {
          let forcat = "ai"
          forcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('loop', () async {
      final res = await exec('''
        @f() {
          let loopcat = "ai"
          loopcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('break', () async {
      final res = await exec('''
        @f() {
          let breakcat = "ai"
          breakcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('continue', () async {
      final res = await exec('''
        @f() {
          let continuecat = "ai"
          continuecat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('if', () async {
      final res = await exec('''
        @f() {
          let ifcat = "ai"
          ifcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('match', () async {
      final res = await exec('''
        @f() {
          let matchcat = "ai"
          matchcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('true', () async {
      final res = await exec('''
        @f() {
          let truecat = "ai"
          truecat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('false', () async {
      final res = await exec('''
        @f() {
          let falsecat = "ai"
          falsecat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });

    test('null', () async {
      final res = await exec('''
        @f() {
          let nullcat = "ai"
          nullcat
        }
        <: f()
      ''');
      expect(res, StrValue('ai'));
    });
  });

  group('name validation of reserved word', () {
    test('def', () {
      expect(
        () async => await exec('''
          let let = 1
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });

    test('attr', () {
      expect(
        () async => await exec('''
          #[let 1]
          @f() { 1 }
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });

    test('ns', () {
      expect(
        () async => await exec('''
          :: let {
            @f() { 1 }
          }
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });

    test('var', () {
      expect(
        () async => await exec('''
          let
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });

    test('prop', () {
      expect(
        () async => await exec('''
          let x = { let: 1 }
          x.let
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });

    test('meta', () {
      expect(
        () async => await exec('''
          ### let 1
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });

    test('fn', () {
      expect(
        () async => await exec('''
          @let() { 1 }
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });
  });
}