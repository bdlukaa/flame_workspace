import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

/// A diagnostic produced while resolving a project's Dart types.
class TypeResolutionDiagnostic {
  final String path;
  final String message;

  const TypeResolutionDiagnostic({required this.path, required this.message});

  @override
  String toString() => '$path: $message';
}

/// Resolves project classes and answers Flame-specific type questions.
///
/// Analyzer elements stay inside this service so parser consumers do not need
/// to depend on Analyzer's resolved model.
class FlameTypeResolver {
  final AnalysisContextCollection _contexts;
  final Map<String, ClassElement> _classes;

  final List<TypeResolutionDiagnostic> diagnostics;

  FlameTypeResolver._(this._contexts, this._classes, this.diagnostics);

  /// Resolves all Dart libraries under [projectRoot]/lib.
  static Future<FlameTypeResolver> forProject(Directory projectRoot) async {
    final root = path.normalize(path.absolute(projectRoot.path));
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final sdkPath = flutterRoot == null
        ? path.dirname(path.dirname(Platform.resolvedExecutable))
        : path.join(flutterRoot, 'bin', 'cache', 'dart-sdk');
    final contexts = AnalysisContextCollection(
      includedPaths: [root],
      sdkPath: sdkPath,
    );
    final resolver = FlameTypeResolver._(contexts, {}, []);
    await resolver._resolveDirectory(Directory(path.join(root, 'lib')));
    return resolver;
  }

  /// Releases Analyzer resources owned by this resolver.
  Future<void> dispose() => _contexts.dispose();

  /// Whether the project class identified by [sourcePath] and [className] is a
  /// `PositionComponent` or a resolved descendant of one.
  bool isFlameComponent({
    required String sourcePath,
    required String className,
  }) {
    final element = _classes[_key(sourcePath, className)];
    if (element == null) return false;

    if (_isFlamePositionComponent(element)) return true;
    return element.allSupertypes.any(_isFlamePositionComponentType);
  }

  Future<void> _resolveDirectory(Directory directory) async {
    if (!directory.existsSync()) {
      diagnostics.add(
        TypeResolutionDiagnostic(
          path: directory.path,
          message: 'The project lib directory does not exist.',
        ),
      );
      return;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && path.extension(entity.path) == '.dart') {
        await _resolveFile(entity.path);
      }
    }
  }

  Future<void> _resolveFile(String filePath) async {
    final normalizedPath = path.normalize(path.absolute(filePath));

    try {
      final context = _contexts.contextFor(normalizedPath);
      final result = await context.currentSession.getResolvedLibrary(
        normalizedPath,
      );

      if (result is! ResolvedLibraryResult) {
        diagnostics.add(
          TypeResolutionDiagnostic(
            path: normalizedPath,
            message: 'Analyzer could not resolve this Dart library.',
          ),
        );
        return;
      }

      for (final unit in result.units) {
        for (final error in unit.diagnostics) {
          diagnostics.add(
            TypeResolutionDiagnostic(
              path: normalizedPath,
              message: error.message,
            ),
          );
        }
      }

      final sourcePath = normalizedPath;
      for (final element in result.element.classes) {
        final name = element.name;
        if (name != null) {
          _classes[_key(sourcePath, name)] = element;
        }
      }
    } catch (error) {
      diagnostics.add(
        TypeResolutionDiagnostic(
          path: normalizedPath,
          message: 'Analyzer resolution failed: $error',
        ),
      );
    }
  }

  bool _isFlamePositionComponent(ClassElement element) {
    return element.name == 'PositionComponent' &&
        _isFlameLibrary(element.library);
  }

  bool _isFlamePositionComponentType(InterfaceType type) {
    final element = type.element;
    return element.name == 'PositionComponent' &&
        _isFlameLibrary(element.library);
  }

  bool _isFlameLibrary(LibraryElement? library) {
    return library?.uri.toString().startsWith('package:flame/') ?? false;
  }

  String _key(String sourcePath, String className) {
    return '${path.normalize(path.absolute(sourcePath))}::$className';
  }
}
