import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('standard', () async {
    final res = await exec('''
      <: Foo:bar()

      :: Foo {
        @bar() { "ai" }
      }
    ''');
    expect(res, StrValue('ai'));
  });

  test('self ref', () async {
    final res = await exec('''
      <: Foo:bar()

      :: Foo {
        let ai = "kawaii"
        @bar() { ai }
      }
    ''');
    expect(res, StrValue('kawaii'));
  });

  test('cannot declare mutable variable', () {
    final ft = exec('''
      :: Foo {
        var value = 0
      }
    ''');
    expect(() async => await ft, throwsA(TypeMatcher<RuntimeError>()));
  });

  group('nested', () {
    test('standard', () async {
      final res = await exec('''
        <: Foo:Bar:baz()

        :: Foo {
          :: Bar {
            @baz() { "ai" }
          }
        }
      ''');
      expect(res, StrValue('ai'));
    });

    test('self ref', () async {
      final res = await exec('''
        <: Foo:Bar:baz()

        :: Foo {
          :: Bar {
            let ai = "kawaii"
            @baz() { ai }
          }
        }
      ''');
      expect(res, StrValue('kawaii'));
    });

    test('self ref var override', () async {
      final res = await exec('''
        <: Foo:Bar:baz()

        :: Foo {
          let ai = "hoge"
          :: Bar {
            let ai = "kawaii"
            @baz() { ai }
          }
        }
      ''');
      expect(res, StrValue('kawaii'));
    });

    test('parent ref', () async {
      final res = await exec('''
        <: Foo:Bar:baz()

        :: Foo {
          let ai = "kawaii"
          :: Bar {
            @baz() { ai }
          }
        }
      ''');
      expect(res, StrValue('kawaii'));
    });

    test('child ref', () async {
      final res = await exec('''
        <: Foo:f()

        :: Foo {
          :: Bar {
            :: Baz {
              let ai = "kawaii"
            }
          }
          @f() { Bar:Baz:ai }
        }
      ''');
      expect(res, StrValue('kawaii'));
    });
  });
}