import 'dart:io';

import 'package:flame_workspace/workbench/assets/asset_discovery.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'discovers declared image files and directories by project-relative path',
    () async {
      final project = await Directory.systemTemp.createTemp('asset_discovery_');
      addTearDown(() => project.delete(recursive: true));

      await File(path.join(project.path, 'pubspec.yaml')).writeAsString('''
name: asset_fixture
flutter:
  assets:
    - assets/images/
    - assets/hero.JPG
    - assets/missing.png
''');
      await Directory(path.join(project.path, 'assets', 'images'))
          .create(recursive: true);
      await File(path.join(project.path, 'assets', 'images', 'player.png'))
          .writeAsBytes(const [1]);
      await File(path.join(project.path, 'assets', 'images', 'enemy.webp'))
          .writeAsBytes(const [1]);
      await File(path.join(project.path, 'assets', 'images', 'readme.txt'))
          .writeAsString('not an image');
      await Directory(path.join(project.path, 'assets', 'unlisted'))
          .create(recursive: true);
      await File(path.join(project.path, 'assets', 'unlisted', 'loose.png'))
          .writeAsBytes(const [1]);
      await File(path.join(project.path, 'assets', 'hero.JPG'))
          .writeAsBytes(const [1]);

      final result = await WorkspaceAssetDiscovery.discover(project);

      expect(result.assets.map((asset) => asset.path), [
        'assets/hero.JPG',
        'assets/images/enemy.webp',
        'assets/images/player.png',
      ]);
      expect(
        result.assets
            .singleWhere((asset) => asset.path == 'assets/hero.JPG')
            .extension,
        '.jpg',
      );
      expect(result.missingPaths, ['assets/missing.png']);
      expect(result.undeclaredPaths, ['assets/unlisted/loose.png']);
      expect(result.diagnostics, isEmpty);
    },
  );

  test(
    'returns diagnostics for malformed or missing project asset configuration',
    () async {
      final project = await Directory.systemTemp.createTemp('asset_discovery_');
      addTearDown(() => project.delete(recursive: true));

      await File(path.join(project.path, 'pubspec.yaml')).writeAsString('''
name: asset_fixture
flutter:
  assets: assets/images/
''');

      final result = await WorkspaceAssetDiscovery.discover(project);

      expect(result.assets, isEmpty);
      expect(result.diagnostics, isNotEmpty);
    },
  );

  test('serializes a semantic component asset reference', () {
    final component = ComponentInstance(
      id: 'sprite',
      type: const ComponentType(
        id: 'SpriteComponent',
        name: 'SpriteComponent',
        isPositionComponent: true,
      ),
      assetPath: 'assets/images/player.png',
    );

    final restored = ComponentInstance.fromJson(component.toJson());

    expect(restored.assetPath, 'assets/images/player.png');
    expect(restored.toJson(), equals(component.toJson()));
  });
}
