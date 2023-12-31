import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('Hello world!', () async {
    final res = await exec('<: "Hello world!"');
    expect(res, StrValue('Hello world!'));
  });

  test('empty script', () async {
    final parser = Parser();
    final res = parser.parse('');
    expect(res.ast, []);
  });

  group('lang version', () {
    test('number', () async {
      final res = Parser.getLangVersion('''
        /// @2021
        @f(x) {
          x
        }
      ''');
      expect(res, '2021');
    });

    test('chars', () async {
      final res = Parser.getLangVersion('''
        /// @ canary
        final a = 1
        @f(x) {
          x
        }
        f(a)
      ''');
      expect(res, 'canary');
    });

    test('complex', () async {
      final res = Parser.getLangVersion('''
        /// @ 2.0-Alpha
        @f(x) {
          x
        }
      ''');
      expect(res, '2.0-Alpha');
    });

    test('not specified', () async {
      final res = Parser.getLangVersion('''
        @f(x) {
          x
        }
      ''');
      expect(res, null);
    });
  });

  group('location', () {
    test('function', () async {
      final parser = Parser();
      final nodes = parser.parse('@f(a) { a }').ast;
      expect(nodes.length, 1);
      final node = nodes[0];
      expect(node.loc, Loc(0, 10));
    });
  });

  group('scope', () {
    final scope = Scope([
      {
        'a': NullValue()
      },
      {
        'a': NumValue(1),
        'b': NumValue(2),
        'c': NumValue(3)
      }
    ]);

    test('keys', () {
      expect(scope.keys, ['a', 'b', 'c']);
    });

    test('values', () {
      expect(scope.values, [NullValue(), NumValue(2), NumValue(3)]);
    });

    test('isEmpty', () {
      expect(scope.isEmpty, false);
      expect(Scope([]).isEmpty, true);
      expect(Scope([{}, {}]).isEmpty, true);
    });

    test('isNotEmpty', () {
      expect(scope.isNotEmpty, true);
    });

    test('containsKey', () {
      expect(scope.containsKey('c'), true);
      expect(scope.containsKey('d'), false);
    });
  });
}