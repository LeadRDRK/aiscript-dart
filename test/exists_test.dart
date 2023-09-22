import 'package:aiscript/aiscript.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  test('basic', () async {
    final res = await exec('''
      let foo = null
      <: [(exists foo) (exists bar)]
    ''');
    expect(res, HasValue([BoolValue(true), BoolValue(false)]));
  });
}