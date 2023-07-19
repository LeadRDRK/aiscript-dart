import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  group('num', () {
		test('to_str', () async {
			final res = await exec('''
        let num = 123
        <: num.to_str()
			''');
			expect(res, StrValue('123'));
		});
	});

	group('str', () {
		test('len', () async {
			final res = await exec('''
        let str = "hello"
        <: str.len
			''');
			expect(res, NumValue(5));
		});

		test('to_num', () async {
			final res = await exec('''
        let str = "123"
        <: str.to_num()
			''');
			expect(res, NumValue(123));
		});

		test('upper', () async {
			final res = await exec('''
        let str = "hello"
        <: str.upper()
			''');
			expect(res, StrValue('HELLO'));
		});

		test('lower', () async {
			final res = await exec('''
        let str = "HELLO"
        <: str.lower()
			''');
			expect(res, StrValue('hello'));
		});

		test('trim', () async {
			final res = await exec('''
        let str = " hello  "
        <: str.trim()
			''');
			expect(res, StrValue('hello'));
		});

		test('replace', () async {
			final res = await exec('''
        let str = "hello"
        <: str.replace("l", "x")
			''');
			expect(res, StrValue('hexxo'));
		});

		test('index_of', () async {
			final res = await exec('''
        let str = "hello"
        <: str.index_of("l")
			''');
			expect(res, NumValue(2));
		});

		test('incl', () async {
			final res = await exec('''
        let str = "hello"
        <: [str.incl("ll"), str.incl("x")]
			''');
			expect(res, HasValue([BoolValue(true), BoolValue(false)]));
		});

		test('split', () async {
			final res = await exec('''
        let str = "a,b,c"
        <: str.split(",")
			''');
			expect(res, HasValue([StrValue('a'), StrValue('b'), StrValue('c')]));
		});

		test('pick', () async {
			final res = await exec('''
        let str = "hello"
        <: str.pick(1)
			''');
			expect(res, StrValue('e'));
		});

		test('slice', () async {
			final res = await exec('''
        let str = "hello"
        <: str.slice(1, 3)
			''');
			expect(res, StrValue('el'));
		});
	});

	group('arr', () {
		test('len', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        <: arr.len
			''');
			expect(res, NumValue(3));
		});

		test('push', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        arr.push(4)
        <: arr
			''');
			expect(res, HasValue([NumValue(1), NumValue(2), NumValue(3), NumValue(4)]));
		});

		test('unshift', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        arr.unshift(4)
        <: arr
			''');
			expect(res, HasValue([NumValue(4), NumValue(1), NumValue(2), NumValue(3)]));
		});

		test('pop', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        let popped = arr.pop()
        <: [popped, arr]
			''');
			expect(res, HasValue([NumValue(3), HasValue([NumValue(1), NumValue(2)])]));
		});

		test('shift', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        let shifted = arr.shift()
        <: [shifted, arr]
			''');
			expect(res, HasValue([NumValue(1), HasValue([NumValue(2), NumValue(3)])]));
		});

		test('concat', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        let concated = arr.concat([4, 5])
        <: [concated, arr]
			''');
			expect(res, HasValue([
				HasValue([NumValue(1), NumValue(2), NumValue(3), NumValue(4), NumValue(5)]),
				HasValue([NumValue(1), NumValue(2), NumValue(3)])
			]));
		});

		test('slice', () async {
			final res = await exec('''
        let arr = ["ant", "bison", "camel", "duck", "elephant"]
        let sliced = arr.slice(2, 4)
        <: [sliced, arr]
			''');
			expect(res, HasValue([
				HasValue([StrValue('camel'), StrValue('duck')]),
				HasValue([StrValue('ant'), StrValue('bison'), StrValue('camel'), StrValue('duck'), StrValue('elephant')])
			]));
		});

		test('join', () async {
			final res = await exec('''
        let arr = ["a", "b", "c"]
        <: arr.join("-")
			''');
			expect(res, StrValue('a-b-c'));
		});

		test('map', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        <: arr.map(@(item) { item * 2 })
			''');
			expect(res, HasValue([NumValue(2), NumValue(4), NumValue(6)]));
		});

		test('map with index', () async
		{
			final res = await exec('''
        let arr = [1, 2, 3]
        <: arr.map(@(item, index) { item * index })
			''');
			expect(res, HasValue([NumValue(0), NumValue(2), NumValue(6)]));
		});

		test('filter', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        <: arr.filter(@(item) { item != 2 })
			''');
			expect(res, HasValue([NumValue(1), NumValue(3)]));
		});

		test('filter with index', () async
		{
			final res = await exec('''
        let arr = [1, 2, 3, 4]
        <: arr.filter(@(item, index) { item != 2 && index != 3 })
			''');
			expect(res, HasValue([NumValue(1), NumValue(3)]));
		});

		test('reduce', () async {
			final res = await exec('''
        let arr = [1, 2, 3, 4]
        <: arr.reduce(@(accumulator, currentValue) { (accumulator + currentValue) })
			''');
			expect(res, NumValue(10));
		});

		test('reduce with index', () async
		{
			final res = await exec('''
        let arr = [1, 2, 3, 4]
        <: arr.reduce(@(accumulator, currentValue, index) { (accumulator + (currentValue * index)) } 0)
			''');
			expect(res, NumValue(20));
		});

		test('find', () async {
			final res = await exec('''
        let arr = ["abc", "def", "ghi"]
        <: arr.find(@(item) { item.incl("e") })
			''');
			expect(res, StrValue('def'));
		});

		test('find with index', () async
		{
			final res = await exec('''
        let arr = ["abc1", "def1", "ghi1", "abc2", "def2", "ghi2"]
        <: arr.find(@(item, index) { item.incl("e") && index > 1 })
			''');
			expect(res, StrValue('def2'));
		});

		test('incl', () async {
			final res = await exec('''
        let arr = ["abc", "def", "ghi"]
        <: [arr.incl("def"), arr.incl("jkl")]
			''');
			expect(res, HasValue([BoolValue(true), BoolValue(false)]));
		});

		test('reverse', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        arr.reverse()
        <: arr
			''');
			expect(res, HasValue([NumValue(3), NumValue(2), NumValue(1)]));
		});

		test('copy', () async {
			final res = await exec('''
        let arr = [1, 2, 3]
        let copied = arr.copy()
        copied.reverse()
        <: [copied, arr]
			''');
			expect(res, HasValue([
				HasValue([NumValue(3), NumValue(2), NumValue(1)]),
				HasValue([NumValue(1), NumValue(2), NumValue(3)])
			]));
		});
    test('sort num array', () async {
        final res = await exec('''
          var arr = [2, 10, 3]
          let comp = @(a, b) { a - b }
          arr.sort(comp)
          <: arr
        ''');
        expect(res, HasValue([NumValue(2), NumValue(3), NumValue(10)]));
    });
    test('sort string array (with Str:lt)', () async {
        final res = await exec('''
          var arr = ["hoge", "huga", "piyo", "hoge"]
          arr.sort(Str:lt)
          <: arr
        ''');
        expect(res, HasValue([StrValue('hoge'), StrValue('hoge'), StrValue('huga'), StrValue('piyo')]));
    });
    test('sort string array (with Str:gt)', () async {
      final res = await exec('''
        var arr = ["hoge", "huga", "piyo", "hoge"]
        arr.sort(Str:gt)
        <: arr
      ''');
      expect(res, HasValue([ StrValue('piyo'),  StrValue('huga'), StrValue('hoge'), StrValue('hoge')]));
    });
    test('sort object array', () async {
      final res = await exec('''
        var arr = [{x: 2}, {x: 10}, {x: 3}]
        let comp = @(a, b) { a.x - b.x }

        arr.sort(comp)
        <: arr
      ''');
      expect(res, HasValue([
        HasValue({'x': NumValue(2)}),
        HasValue({'x': NumValue(3)}), 
        HasValue({'x': NumValue(10)})
      ]));
    });
  });
}