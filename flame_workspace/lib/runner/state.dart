library project_state;

import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/parser/generator.dart';
import 'package:flame_workspace/parser/parser.dart';
import 'package:flame_workspace/project/objects/built_in_components.dart';
import 'package:flame_workspace/project/objects/component.dart';
import 'package:flame_workspace/project/objects/scene.dart';
import 'package:flame_workspace/project/project.dart';
import 'package:flutter/material.dart';

class FlameProjectState with ChangeNotifier {
  final FlameProject project;

  FlameProjectState(this.project) {
    files = project.location.listSync(recursive: true);
    _filesSubscription =
        project.location.watch(recursive: true).listen((FileSystemEvent event) {
      project.location.list(recursive: true).toList().then((value) {
        files = value;
        notifyListeners();
      });
      if (!event.path.endsWith('.dart')) return;
      // print(event);
      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
        case FileSystemEvent.move:
          indexProject(includeOnly: [event.path]);
          break;
        case FileSystemEvent.delete:
          indexed?.removeWhere((e) => e.$1['source'] == event.path);
          notifyListeners();
          break;
      }
    });
    indexProject();

    _currentScene = scenes.map((e) => e.$1).firstWhere(
          (scene) => scene.name == project.initialScene,
          orElse: () => scenes.first.$1,
        );
  }

  List<FileSystemEntity> files = [];
  late final StreamSubscription<FileSystemEvent> _filesSubscription;

  final scenes = <SceneResult>[];
  late FlameSceneObject _currentScene;
  FlameSceneObject get currentScene => _currentScene;

  final components = <ComponentResult>[];

  FlameComponentObject? _selectedComponent;
  FlameComponentObject? get selectedComponent => _selectedComponent;
  set selectedComponent(FlameComponentObject? value) {
    _selectedComponent = value;
    notifyListeners();
  }

  bool isIndexing = false;

  ProjectIndexResult? indexed;

  /// Indexes the current project.
  ///
  /// If [includeOnly] is not null, only the files that are in the list will be
  /// indexed.
  ///
  /// If [onlyParse] is true, the project will not be indexed, only parsed.
  void indexProject({
    Iterable<String>? includeOnly,
    bool onlyParse = false,
  }) async {
    isIndexing = true;
    if (includeOnly == null || includeOnly.isEmpty) {
      indexed = null;
    }
    notifyListeners();
    if (!onlyParse) {
      final result = await ProjectIndexer.indexProject(
        project.location,
        includeOnly,
      );
      indexed ??= [];
      if (includeOnly != null && includeOnly.isNotEmpty) {
        indexed!
          ..removeWhere((e) => includeOnly.contains(e.$1['source']))
          ..addAll(result);
      } else {
        indexed!.clear();
        indexed!.addAll(result);
      }
    }
    if (indexed != null) {
      components
        ..clear()
        ..addAll(ProjectIndexer.components(indexed!));
      scenes
        ..clear()
        ..addAll(ProjectIndexer.scenes(indexed!));
    }

    if ((includeOnly == null || includeOnly.isEmpty) && !onlyParse) {
      await PropertiesGenerator.writeForComponents(
        [...components.map((e) => e.$1), ...builtInComponents],
        project,
      );

      for (final scene in scenes) {
        await SceneGenerator.writeForScene(scene.$1, project);
      }
    } else if ((includeOnly != null && includeOnly.isNotEmpty) && !onlyParse) {
      for (final scene in scenes) {
        if (includeOnly.contains(scene.$1.filePath)) {
          await SceneGenerator.writeForScene(scene.$1, project);
        }
      }
    }

    isIndexing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _filesSubscription.cancel();
    super.dispose();
  }
}
