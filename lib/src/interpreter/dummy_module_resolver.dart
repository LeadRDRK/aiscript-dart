import 'module_resolver.dart';
import '../core/error.dart';

class DummyModuleResolver implements ModuleResolver {
  const DummyModuleResolver();

  @override
  Future<ResolvedModule> resolve(String path) async =>
      throw RuntimeError('attempt to resolve module with DummyModuleResolver');
  
  @override
  Future<String?> resolvePath(String name, String? currentPath) async => null;
}