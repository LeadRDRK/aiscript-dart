import 'module_resolver.dart';

/// A dummy module resolver. Always fails to resolve any module.
class DummyModuleResolver implements ModuleResolver {
  const DummyModuleResolver();

  @override
  Future<ResolvedModule> resolve(String path) async =>
      throw UnsupportedError('attempt to resolve module with DummyModuleResolver');
  
  @override
  Future<String?> resolvePath(String name, String? currentPath) async => null;
}