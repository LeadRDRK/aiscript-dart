import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
	test('basic', () async {
		final res = await exec('''
      var count = 0
      for (let i, 10) {
        count += i + 1
      }
      <: count
		''');
		expect(res, NumValue(55));
	});

	test('initial value', () async {
		final res = await exec('''
      var count = 0
      for (let i = 2, 10) {
        count += i
      }
      <: count
		''');
		expect(res, NumValue(65));
	});

	test('without iterator', () async {
		final res = await exec('''
      var count = 0
      for (10) {
        count = (count + 1)
      }
      <: count
		''');
		expect(res, NumValue(10));
	});

	test('without brackets', () async {
		final res = await exec('''
      var count = 0
      for let i, 10 {
        count = (count + i)
      }
      <: count
		''');
		expect(res, NumValue(45));
	});

	test('break', () async {
		final res = await exec('''
      var count = 0
      for (let i, 20) {
        if (i == 11) break
        count += i
      }
      <: count
		''');
		expect(res, NumValue(55));
	});

	test('continue', () async {
		final res = await exec('''
      var count = 0
      for (let i, 10) {
        if (i == 5) continue
        count = (count + 1)
      }
      <: count
		''');
		expect(res, NumValue(9));
	});

	test('single statement', () async {
		final res = await exec('''
      var count = 0
      for 10 count += 1
      <: count
		''');
		expect(res, NumValue(10));
	});

	test('var name without space', () {
    expect(() async =>
			await exec('''
        for (leti, 10) {
          <: i
        }
			'''),
      throwsA(TypeMatcher<SyntaxError>())
    );
	});
}