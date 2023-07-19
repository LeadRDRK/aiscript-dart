import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('item access', () async {
		final res = await exec('''
      let arr = ["murakami", "san", "kawaii"]
      <: arr[1]
		''');
		expect(res, StrValue('san'));
	});

  test('item assign', () async {
		final res = await exec('''
      let arr = ["murakami", "san", "kawaii"]
      arr[1] = "chan"
      <: arr
		''');
		expect(res, HasValue([StrValue('murakami'), StrValue('chan'), StrValue('kawaii')]));
	});

  test('item access out of range', () {
		expect(() async => await exec('<: [42][1]'), throwsA(TypeMatcher<IndexOutOfRangeError>()));
	});

  test('item assign out of range', () async {
    final res = await exec('''
      let arr = ["murakami", "san"]
      arr[3] = "kawaii"
      <: arr
		''');
		expect(res, HasValue([StrValue('murakami'), StrValue('san'), NullValue(), StrValue('kawaii')]));
  });
}