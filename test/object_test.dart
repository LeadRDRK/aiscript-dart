import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('property access', () async {
		final res = await exec('''
      let obj = {
        a: {
          b: {
            c: 42;
          };
        };
      }

      <: obj.a.b.c
		''');
		expect(res, NumValue(42));
	});

  test('property access (fn call)', () async {
		final res = await exec('''
      @f() { 42 }

      let obj = {
        a: {
          b: {
            c: f;
          };
        };
      }

      <: obj.a.b.c()
		''');
		expect(res, NumValue(42));
	});

  test('property assign', () async {
		final res = await exec('''
      let obj = {
        a: 1
        b: {
          c: 2
          d: {
            e: 3
          }
        }
      }

      obj.a = 24
      obj.b.d.e = 42

      <: obj
		''');
		expect(res, HasValue({
      'a': NumValue(24),
      'b': HasValue({
        'c': NumValue(2),
        'd': HasValue({
          'e': NumValue(42),
        })
      })
    }));
	});
}