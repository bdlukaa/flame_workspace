library project_state;

import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/properties_generator.dart';
import 'package:flame_workspace/workbench/generators/scene_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../parser/parser.dart';
import '../project/objects/built_in_components.dart';
import '../project/objects/component.dart';
import '../project/objects/scene.dart';
import '../project/project.dart';

class FlameProjectState with ChangeNotifier {
  final FlameProject project;

  bool initialized = false;

  FlameProjectState(this.project) {
    files = project.location.listSync();
    sortFiles(files);
    _filesSubscription =
        project.location.watch(recursive: true).listen((FileSystemEvent event) {
      // Only listen to dart files and ignore generated files.
      if (!event.path.endsWith('.dart') ||
          event.path.contains(
            path.join(project.name, 'lib', 'generated'),
          )) return;

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
          indexed?.removeWhere((e) => e.$1['source'] == event.path);
          notifyListeners();
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

  final scenes = <IndexedScene>[];
  FlameSceneObject get currentScene => scenes.map((e) => e.$1).firstWhere(
        (scene) => scene.name == project.initialScene,
        orElse: () => scenes.first.$1,
      );

  final components = <IndexedComponent>[];

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

    isIndexing = false;
    notifyListeners();
  }

  static Future<(IndexedProject?, List<IndexedComponent>, List<IndexedScene>)>
      _indexProject(Map data) async {
    final project = data['project'] as FlameProject;
    final includeOnly = data['includeOnly'] as Iterable<String>?;
    final onlyParse = data['onlyParse'] as bool;
    var indexed = data['indexed'] as IndexedProject?;
    var components = <IndexedComponent>[];
    var scenes = <IndexedScene>[];

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
      components
        ..clear()
        ..addAll(ProjectIndexer.componentsFrom(indexed));
      scenes
        ..clear()
        ..addAll(ProjectIndexer.scenesFrom(indexed));
    }

    if ((includeOnly == null || includeOnly.isEmpty) && !onlyParse) {
      await PropertiesGenerator.writeForComponents(
        [...components.map((e) => e.$1), ...builtInComponents],
        project,
      );

      for (final scene in scenes) {
        await SceneGenerator.writeForScene(scene.$1, project);
      }
      await SceneGenerator.writeSetScenes(project, scenes.map((e) => e.$1));
    } else if ((includeOnly != null && includeOnly.isNotEmpty) && !onlyParse) {
      for (final scene in scenes) {
        if (includeOnly.contains(scene.$1.filePath)) {
          await SceneGenerator.writeForScene(scene.$1, project);
        }
      }
      await SceneGenerator.writeSetScenes(project, scenes.map((e) => e.$1));
    }

    return (indexed, components, scenes);
  }

  @override
  void dispose() {
    _filesSubscription.cancel();
    super.dispose();
  }
}
