import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('if', () async {
    final res1 = await exec('''
      var msg = "ai"
      if true {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res1, StrValue('kawaii'));

    final res2 = await exec('''
      var msg = "ai"
      if false {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res2, StrValue('ai'));
  });

  test('else', () async {
    final res1 = await exec('''
      var msg = null
      if true {
        msg = "ai"
      } else {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res1, StrValue('ai'));

    final res2 = await exec('''
      var msg = null
      if false {
        msg = "ai"
      } else {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res2, StrValue('kawaii'));
  });

  test('elif', () async {
    final res1 = await exec('''
      var msg = "bebeyo"
      if false {
        msg = "ai"
      } elif true {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res1, StrValue('kawaii'));

    final res2 = await exec('''
      var msg = "bebeyo"
      if false {
        msg = "ai"
      } elif false {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res2, StrValue('bebeyo'));
  });

  test('if ~ elif ~ else', () async {
    final res1 = await exec('''
      var msg = null
      if false {
        msg = "ai"
      } elif true {
        msg = "chan"
      } else {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res1, StrValue('chan'));

    final res2 = await exec('''
    var msg = null
      if false {
        msg = "ai"
      } elif false {
        msg = "chan"
      } else {
        msg = "kawaii"
      }
      <: msg
    ''');
    expect(res2, StrValue('kawaii'));
  });

  test('expr', () async {
    final res1 = await exec('''
      <: if true "ai" else "kawaii"
    ''');
    expect(res1, StrValue('ai'));

    final res2 = await exec('''
      <: if false "ai" else "kawaii"
    ''');
    expect(res2, StrValue('kawaii'));
  });
}