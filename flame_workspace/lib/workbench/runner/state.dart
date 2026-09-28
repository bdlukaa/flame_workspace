library project_state;

import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_generator.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../parser/parser.dart';
import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';

class FlameProjectState with ChangeNotifier {
  final FlameProject project;

  bool initialized = false;

  FlameProjectState(this.project) {
    files = project.location.listSync();
    sortFiles(files);
    _filesSubscription = project.location.watch(recursive: true).listen((
      FileSystemEvent event,
    ) {
      // Only listen to dart files and ignore generated files.
      if (!event.path.endsWith('.dart') ||
          event.path.contains(path.join(project.name, 'lib', 'generated'))) {
        return;
      }

      project.location.list().toList().then((value) {
        files = value;
        sortFiles(files);
        notifyListeners();
      });

      // print(event);
      switch (event.type) {
        case FileSystemEvent.modify:
          final modifyEvent = event as FileSystemModifyEvent;
          if (modifyEvent.contentChanged) {
            indexProject(includeOnly: [event.path]);
          }
          break;
        case FileSystemEvent.create:
        case FileSystemEvent.move:
          indexProject(includeOnly: [event.path]);
          break;
        case FileSystemEvent.delete:
          indexProject();
          break;
      }
    });
    indexProject().then((value) {
      initialized = true;
      notifyListeners();
    });
  }

  List<FileSystemEntity> files = [];
  late final StreamSubscription<FileSystemEvent> _filesSubscription;
  void sortFiles(List<FileSystemEntity> files) {
    files.sort((a, b) {
      if (a is Directory && b is File) {
        return -1;
      } else if (a is File && b is Directory) {
        return 1;
      } else {
        return a.path.compareTo(b.path);
      }
    });
  }

  late var _currentSceneName = project.initialScene;
  final scenes = <IndexedScene>[];
  FlameSceneObject get currentScene => scenes
      .map((e) => e.$1)
      .firstWhere(
        (scene) => scene.name == _currentSceneName,
        orElse: () => scenes.first.$1,
      );
  set currentScene(FlameSceneObject value) {
    _currentSceneName = value.name;
    notifyListeners();
  }

  final components = <IndexedComponent>[];
  final flameComponents = <FlameComponentObject>[];
  final flameMixins = <FlameMixin>[];

  FlameComponentObject? _selectedComponent;
  FlameComponentObject? get selectedComponent => _selectedComponent;
  set selectedComponent(FlameComponentObject? value) {
    _selectedComponent = value;
    notifyListeners();
  }

  bool isIndexing = false;

  IndexedProject? indexed;

  /// Indexes the current project.
  ///
  /// If [includeOnly] is not null, only the files that are in the list will be
  /// indexed.
  ///
  /// If [onlyParse] is true, the project will not be indexed, only parsed.
  Future<void> indexProject({
    Iterable<String>? includeOnly,
    bool onlyParse = false,
  }) async {
    isIndexing = true;
    if (includeOnly == null || includeOnly.isEmpty) indexed = null;
    notifyListeners();

    final (
      indexedResult,
      componentsResult,
      scenesResult,
      flameComponentsResult,
      flameMixinsResult,
    ) = await compute(_indexProject, {
      'project': project,
      'indexed': indexed,
      'includeOnly': includeOnly,
      'onlyParse': onlyParse,
    });

    indexed = indexedResult;
    components
      ..clear()
      ..addAll(componentsResult);
    if (scenesResult.isNotEmpty) {
      scenes
        ..clear()
        ..addAll(scenesResult);
    }
    flameComponents
      ..clear()
      ..addAll(flameComponentsResult);
    flameMixins
      ..clear()
      ..addAll(flameMixinsResult);

    isIndexing = false;
    notifyListeners();
  }

  static Future<
    (
      IndexedProject?,
      List<IndexedComponent>,
      List<IndexedScene>,
      List<FlameComponentObject>,
      List<FlameMixin>,
    )
  >
  _indexProject(Map data) async {
    try {
      final project = data['project'] as FlameProject;
      final includeOnly = data['includeOnly'] as Iterable<String>?;
      final onlyParse = data['onlyParse'] as bool;
      var indexed = data['indexed'] as IndexedProject?;
      var components = <IndexedComponent>[];
      var scenes = <IndexedScene>[];
      var flameComponents = <FlameComponentObject>[];
      var flameMixins = <FlameMixin>[];

      if (!onlyParse) {
        final result = await ProjectIndexer.indexProject(
          project.location,
          includeOnly,
        );
        indexed ??= [];
        if (includeOnly != null && includeOnly.isNotEmpty) {
          indexed
            ..removeWhere((e) => includeOnly.contains(e.$1['source']))
            ..addAll(result);
        } else {
          indexed.clear();
          indexed.addAll(result);
        }
      }
      if (indexed != null) {
        final resolver = await FlameTypeResolver.forProject(project.location);
        components
          ..clear()
          ..addAll(ProjectIndexer.componentsFrom(indexed, resolver: resolver));
        scenes
          ..clear()
          ..addAll(ProjectIndexer.scenesFrom(indexed, resolver: resolver));
        flameComponents = resolver.flameComponents;
        flameMixins = resolver.flameMixins;
        await resolver.dispose();
      }

      if ((includeOnly == null || includeOnly.isEmpty) && !onlyParse) {
        await PropertiesGenerator.writeForComponents([
          ...components.map((e) => e.$1),
          ...flameComponents,
        ], project);

        for (final scene in scenes) {
          await SceneGenerator.writeForScene(scene.$1, project);
          await SceneGenerator.writeSetScenes(project, [scene.$1]);
        }
      } else if ((includeOnly != null && includeOnly.isNotEmpty) &&
          !onlyParse) {
        for (final scene in scenes) {
          if (includeOnly.contains(scene.$1.filePath)) {
            await SceneGenerator.writeForScene(scene.$1, project);
            await SceneGenerator.writeSetScenes(project, [scene.$1]);
          }
        }
      }

      return (indexed, components, scenes, flameComponents, flameMixins);
    } catch (error, stack) {
      debugPrint('Failed to index project: $error \n $stack');
      return (
        null,
        <IndexedComponent>[],
        <IndexedScene>[],
        <FlameComponentObject>[],
        <FlameMixin>[],
      );
    }
  }

  @override
  void dispose() {
    _filesSubscription.cancel();
    super.dispose();
  }
}
