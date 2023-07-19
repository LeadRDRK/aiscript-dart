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

  group('location', () => {
    test('function', () async {
      final parser = Parser();
      final nodes = parser.parse('@f(a) { a }').ast;
      expect(nodes.length, 1);
      final node = nodes[0];
      expect(node.loc, Loc(0, 10));
    })
  });
}