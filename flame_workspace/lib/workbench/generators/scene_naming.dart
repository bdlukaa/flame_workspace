import 'package:recase/recase.dart';

/// The canonical mapping between a scene's semantic name and its Dart files.
class WorkspaceSceneNaming {
  const WorkspaceSceneNaming._();

  static String normalize(String name) => ReCase(name.trim()).pascalCase;

  static String fileName(String name) => normalize(name).snakeCase;

  static String baseClassName(String name) => '\$Scene${normalize(name)}';

  static String behaviorClassName(String name) => normalize(name);

  static String scriptFileName(String name) => '${fileName(name)}_script.dart';
}
