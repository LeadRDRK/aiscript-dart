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

	test('assign variable', () async {
		final res = await exec('''
      Foo:setMsg("hello")
      <: Foo:getMsg()

      :: Foo {
        var msg = "ai"
        @setMsg(value) { Foo:msg = value }
        @getMsg() { Foo:msg }
      }
		''');
		expect(res, StrValue('hello'));
	});

	test('increment', () async {
		final res = await exec('''
      Foo:value += 10
      Foo:value -= 5
      <: Foo:value

      :: Foo {
        var value = 0
      }
		''');
		expect(res, NumValue(5));
	});
}