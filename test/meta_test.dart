import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('default meta', () async {
    final res = getMeta('''
      ### { a: 1; b: 2; c: 3; }
    ''');
    expect(res, {
      '': {
        'a': 1,
        'b': 2,
        'c': 3,
      }
    });
  });

  group('String', () {
    test('valid', () async {
      final res = getMeta('''
      ### x "hoge"
      ''');
      expect(res, {
        'x': 'hoge'
      });
    });
  });

  group('Number', () {
    test('valid', () async {
      final res = getMeta('''
      ### x 42
      ''');
      expect(res, {
        'x': 42
      });
    });
  });

  group('Boolean', () {
    test('valid', () async {
      final res = getMeta('''
      ### x true
      ''');
      expect(res, {
        'x': true
      });
    });
  });

  group('Null', () {
    test('valid', () async {
      final res = getMeta('''
      ### x null
      ''');
      expect(res, {
        'x': null
      });
    });
  });

  group('Array', () {
    test('valid', () async {
      final res = getMeta('''
      ### x [1 2 3]
      ''');
      expect(res, {
        'x': [1, 2, 3]
      });
    });

    test('invalid', () {
      expect(() =>
        getMeta('''
          ### x [1 (2 + 2) 3]
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });
  });

  group('Object', () {
    test('valid', () async {
      final res = getMeta('''
      ### x { a: 1; b: 2; c: 3; }
      ''');
      expect(res, {
        'x': {
          'a': 1,
          'b': 2,
          'c': 3,
        }
      });
    });

    test('invalid', () {
      expect(() =>
        getMeta('''
          ### x { a: 1; b: (2 + 2); c: 3; }
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });
  });

  group('Template', () {
    test('invalid', () {
      expect(() =>
        getMeta('''
          ### x \'''foo {bar} baz\'''
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });
  });

  group('Expression', () {
    test('invalid', () {
      expect(() =>
        getMeta('''
          ### x (1 + 1)
        '''),
        throwsA(TypeMatcher<SyntaxError>())
      );
    });
  });
}