import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import 'flame_api.dart';
import 'writer.dart';

/// A diagnostic produced while resolving a project's Dart types.
class const TypeResolutionDiagnostic({
  required final String path,
  required final String message,
}) {
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
  final String _projectRoot;

  final List<TypeResolutionDiagnostic> diagnostics;
  late FlameApiCatalog flameApi;
  int lastFlameApiDiscoveryMs = 0;
  final Set<String> _sourcePaths = {};

  FlameTypeResolver._(
    this._contexts,
    this._classes,
    this.diagnostics,
    this._projectRoot,
  );

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
    final resolver = FlameTypeResolver._(contexts, {}, [], root);
    await resolver._collectSourcePaths(Directory(path.join(root, 'lib')));
    await resolver._resolvePaths(resolver._sourcePaths);
    final flameApiTimer = Stopwatch()..start();
    resolver.flameApi = await FlameApiDiscovery.resolve(
      contexts: contexts,
      projectRoot: root,
      diagnostics: resolver.diagnostics,
    );
    resolver.lastFlameApiDiscoveryMs = flameApiTimer.elapsedMilliseconds;
    return resolver;
  }

  /// Reuses Analyzer state for source changes and preserves Flame API metadata.
  Future<void> refresh(Iterable<String> changedPaths) async {
    lastFlameApiDiscoveryMs = 0;
    final changed = changedPaths
        .map((file) => path.normalize(path.absolute(file)))
        .toSet();
    diagnostics.clear();
    for (final file in changed) {
      _contexts.contextFor(file).changeFile(file);
      _sourcePaths.remove(file);
      _classes.removeWhere((key, _) => key.startsWith('$file::'));
      if (File(file).existsSync() &&
          path.extension(file) == '.dart' &&
          !isWorkspaceGeneratedDartFile(file, projectPath: _projectRoot)) {
        final parsed = parseFile(
          path: file,
          featureSet: FeatureSet.latestLanguageVersion(),
          throwIfDiagnostics: false,
        );
        if (!parsed.unit.directives.any(
          (directive) => directive is PartOfDirective,
        )) {
          _sourcePaths.add(file);
        }
      }
    }
    await _resolvePaths(_sourcePaths);
  }

  /// Flame component metadata discovered from the project's resolved package.
  List<FlameComponentObject> get flameComponents => flameApi.componentObjects;

  /// Flame mixin metadata discovered from the project's resolved package.
  List<FlameMixin> get flameMixins => flameApi.mixins;

  /// Returns transform properties inherited from Flame ancestors of a project
  /// component. Analyzer elements remain private to this resolver.
  List<FlameComponentField> inheritedComponentFields({
    required String sourcePath,
    required String className,
  }) {
    final element = _classes[_key(sourcePath, className)];
    if (element == null) return const [];

    final fields = <String, FlameComponentField>{};
    for (final supertype in element.allSupertypes) {
      if (!_isFlameLibrary(supertype.element.library)) continue;
      final metadata = flameApi.classFor(supertype.element.name ?? '');
      if (metadata == null) continue;
      for (final property in metadata.transformProperties) {
        fields.putIfAbsent(
          property.name,
          () => FlameComponentField(
            property.name,
            property.type,
            null,
            ['PositionComponent'],
            false,
            false,
            property.hasSetter,
            property.namedValues,
          ),
        );
      }
    }
    return fields.values.toList();
  }

  /// Resolved writable properties are separate from constructor parameters.
  List<FlameComponentProperty> writableComponentProperties({
    required String sourcePath,
    required String className,
  }) {
    final element = _classes[_key(sourcePath, className)];
    if (element == null) return const [];
    final properties = <String, FlameComponentProperty>{};
    for (final member in element.interfaceMembers.values) {
      if (member is! GetterElement || member.isStatic) continue;
      final setter = member.correspondingSetter;
      final name = member.displayName;
      final type = setter?.formalParameters.firstOrNull?.type;
      if (setter == null || name.startsWith('_') || type == null) continue;
      properties[name] = FlameComponentProperty(
        name: name,
        type: type.getDisplayString(),
        typeAccessible: _isTypeAccessible(type),
      );
    }
    return properties.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  bool _isTypeAccessible(DartType type) {
    if (type is FunctionType || type is TypeParameterType) return false;
    final typeElement = type.element;
    if (typeElement is InterfaceElement &&
        !typeElement.library.isDartCore &&
        !flameApi.exposesType(
          typeElement.name ?? '',
          typeElement.library.uri,
        )) {
      return false;
    }
    return type is! InterfaceType ||
        type.typeArguments.every(_isTypeAccessible);
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

  Future<void> _collectSourcePaths(Directory directory) async {
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
      if (entity is File &&
          path.extension(entity.path) == '.dart' &&
          !isWorkspaceGeneratedDartFile(
            entity.path,
            projectPath: path.dirname(directory.path),
          )) {
        final parsed = parseFile(
          path: entity.path,
          featureSet: FeatureSet.latestLanguageVersion(),
          throwIfDiagnostics: false,
        );
        if (!parsed.unit.directives.any(
          (directive) => directive is PartOfDirective,
        )) {
          _sourcePaths.add(path.normalize(path.absolute(entity.path)));
        }
      }
    }
  }

  Future<void> _resolvePaths(Iterable<String> filePaths) async {
    for (final filePath in filePaths) {
      await _resolveFile(filePath);
    }
  }

  Future<void> _resolveFile(String filePath) async {
    final normalizedPath = path.normalize(path.absolute(filePath));

    try {
      final parsed = parseFile(
        path: normalizedPath,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      if (parsed.unit.directives.any(
        (directive) => directive is PartOfDirective,
      )) {
        return;
      }
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
      if (error is InconsistentAnalysisException) {
        // A project edit can invalidate Analyzer state mid-resolution. Apply
        // queued file changes and retry this library once against fresh state.
        final context = _contexts.contextFor(normalizedPath);
        try {
          await context.applyPendingFileChanges();
          final result = await context.currentSession.getResolvedLibrary(
            normalizedPath,
          );
          if (result is ResolvedLibraryResult) {
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
            for (final element in result.element.classes) {
              final name = element.name;
              if (name != null) _classes[_key(normalizedPath, name)] = element;
            }
            return;
          }
          diagnostics.add(
            TypeResolutionDiagnostic(
              path: normalizedPath,
              message:
                  'Analyzer could not resolve this Dart library after retry.',
            ),
          );
        } on Object {
          diagnostics.add(
            TypeResolutionDiagnostic(
              path: normalizedPath,
              message: 'Analyzer result was stale after a project change; this file was skipped for this indexing pass.',
            ),
          );
        }
        return;
      }
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
