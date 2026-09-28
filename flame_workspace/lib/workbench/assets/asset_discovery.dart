import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// An image asset declared by a Flutter project's `flutter.assets` list.
class WorkspaceAsset {
  final String path;
  final String absolutePath;

  const WorkspaceAsset({required this.path, required this.absolutePath});

  String get extension => p.extension(path).toLowerCase();

  String get id => 'asset:$path';

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAsset && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}

/// Results from scanning the assets declared in a Flutter project.
class AssetDiscoveryResult {
  final List<WorkspaceAsset> assets;
  final List<String> missingPaths;
  final List<String> diagnostics;

  const AssetDiscoveryResult({
    this.assets = const [],
    this.missingPaths = const [],
    this.diagnostics = const [],
  });
}

/// Discovers the image files that a Flutter project declares as assets.
class WorkspaceAssetDiscovery {
  const WorkspaceAssetDiscovery._();

  static const imageExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  static Future<AssetDiscoveryResult> discover(Directory projectRoot) async {
    final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      return AssetDiscoveryResult(
        diagnostics: ['No pubspec.yaml found at ${pubspec.path}.'],
      );
    }

    final Object? yaml;
    try {
      yaml = loadYaml(await pubspec.readAsString());
    } on Object catch (error) {
      return AssetDiscoveryResult(
        diagnostics: ['Could not parse ${pubspec.path}: $error'],
      );
    }

    final flutter = yaml is YamlMap ? yaml['flutter'] : null;
    final declarations = flutter is YamlMap ? flutter['assets'] : null;
    if (declarations == null) return const AssetDiscoveryResult();
    if (declarations is! YamlList && declarations is! List) {
      return const AssetDiscoveryResult(
        diagnostics: ['The flutter.assets declaration must be a list.'],
      );
    }

    final assets = <String, WorkspaceAsset>{};
    final missingPaths = <String>[];
    final diagnostics = <String>[];
    for (final declaration in declarations as Iterable<Object?>) {
      if (declaration is! String || declaration.trim().isEmpty) {
        diagnostics.add('Ignoring a non-string or empty asset declaration.');
        continue;
      }

      final declaredPath = _assetPath(declaration);
      final absolutePath = p.normalize(
        p.joinAll([projectRoot.path, ...declaredPath.split('/')]),
      );
      final entityType = await FileSystemEntity.type(absolutePath);
      switch (entityType) {
        case FileSystemEntityType.file:
          _addFile(assets, projectRoot, absolutePath);
        case FileSystemEntityType.directory:
          await for (final entity in Directory(
            absolutePath,
          ).list(recursive: true)) {
            if (entity is File) _addFile(assets, projectRoot, entity.path);
          }
        case FileSystemEntityType.notFound:
          missingPaths.add(declaredPath);
        case FileSystemEntityType.pipe:
        case FileSystemEntityType.unixDomainSock:
        case FileSystemEntityType.link:
          diagnostics.add('Ignoring unsupported asset path: $declaredPath');
      }
    }

    final sortedAssets = assets.values.toList()
      ..sort((first, second) => first.path.compareTo(second.path));
    missingPaths.sort();
    diagnostics.sort();
    return AssetDiscoveryResult(
      assets: sortedAssets,
      missingPaths: missingPaths,
      diagnostics: diagnostics,
    );
  }

  static void _addFile(
    Map<String, WorkspaceAsset> assets,
    Directory projectRoot,
    String filePath,
  ) {
    final relativePath = p.relative(
      p.normalize(filePath),
      from: p.normalize(projectRoot.path),
    );
    final assetPath = relativePath.split(p.separator).join('/');
    if (!imageExtensions.contains(p.extension(assetPath).toLowerCase())) {
      return;
    }
    assets[assetPath] = WorkspaceAsset(
      path: assetPath,
      absolutePath: p.normalize(filePath),
    );
  }

  static String _assetPath(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    return normalized.startsWith('./') ? normalized.substring(2) : normalized;
  }
}
