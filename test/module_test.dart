import 'package:aiscript/aiscript.dart';
import 'package:aiscript/file_module_resolver.dart';
import 'package:test/test.dart';
import 'utils.dart';

final parser = Parser();

class TestModuleResolver implements ModuleResolver {
  const TestModuleResolver(this.modules);
  final Map<String, String> modules;

  @override
  Future<ResolvedModule> resolve(String path) async =>
      ResolvedModule.fromParseResult(parser.parse(modules[path]!));

  @override
  Future<String?> resolvePath(String name, String? currentPath) async =>
      modules.containsKey(name) ? name : null;
}

void main() {
  test('simple', () async {
    const mr = TestModuleResolver({
      'my_module': 'return "ai"'
    });
    final res = await exec('''
      <: require("my_module")
    ''',
    moduleResolver: mr);
    expect(res, StrValue('ai'));
  });

  test('lifecycle', () async {
    const mr = TestModuleResolver({
      'module1': 'return {a: 9}',
      'module2': '''
        let module1 = require("module1")
        module1.a += 1
        return module1.a
      '''
    });
    final res = await exec('''
      let module1 = require("module1")
      module1.a = 21
      let b = require("module2")
      let c = require("module2")
      <: [module1.a, b, c]
    ''',
    moduleResolver: mr);
    expect(res, HasValue([NumValue(22), NumValue(22), NumValue(22)]));
  });

  test('circular dependency', () {
    const mr = TestModuleResolver({
      'module1': 'require("module2")',
      'module2': 'require("module3")',
      'module3': 'require("module1")'
    });
    final ft = exec('require("module1")', moduleResolver: mr);
    expect(() async => await ft, throwsA(TypeMatcher<RuntimeError>()));
  });

  group('FileModuleResolver', () {
    test('simple', () async {
      final mr = FileModuleResolver(parser);
      final res = await exec('''
        let m = require("test/modules/test")
        m.a = 9
        <: require("test/modules/test").a
      ''',
      moduleResolver: mr);
      expect(res, NumValue(9));
    });

    test('module paths', () async {
      final mr = FileModuleResolver(parser, paths: ['test/modules/dir', 'test/modules']);
      final res = await exec('''
        let m = require("test")
        let m2 = require("test2")
        <: [m.a, m2]
      ''',
      moduleResolver: mr);
      expect(res, HasValue([NumValue(24), StrValue('Hello world!')]));
    });

    test('no extension', () async {
      final mr = FileModuleResolver(parser, ext: null);
      final res = await exec('''
        <: require("test/modules/test.aiscript").a
      ''',
      moduleResolver: mr);
      expect(res, NumValue(12));
    });

    test('circular dependency', () {
      final mr = FileModuleResolver(parser, paths: ['test/modules']);
      final ft = exec('require("circular1")', moduleResolver: mr);
      expect(() async => await ft, throwsA(TypeMatcher<RuntimeError>()));
    });
  });
}