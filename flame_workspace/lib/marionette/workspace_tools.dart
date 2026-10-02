import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:flame_workspace_protocol/runtime.dart';

import '../workbench/model/runtime_tree_reconciliation.dart';
import '../workbench/model/semantic_model.dart';
import '../workbench/model/workspace_diagnostic.dart';
import '../workbench/parser/component_capabilities.dart';

import 'workbench_mount_handshake.dart';
import '../workbench/project/import.dart';
import '../workbench/project/workspace_navigation.dart';
import '../workbench/runner/runner.dart';
import '../workbench/runner/state.dart';

FlameProjectState? _state;
FlameProjectRunner? _runner;
var _registered = false;
GlobalKey<NavigatorState>? _navigatorKey;
final _mountHandshake = WorkbenchMountHandshake();
String? _openingProjectPath;
bool _openingFixture = false;
const _mountTimeout = Duration(seconds: 15);

/// Registers the small, read-oriented Marionette API used to inspect the
/// Workspace during development and integration tests.
///
/// The extensions intentionally do not expose generic model or runtime
/// mutation. Normal editor workflows must still be exercised through the UI.
void initializeWorkspaceMarionetteTools({
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  if (!kDebugMode) return;
  _navigatorKey = navigatorKey;
  if (_registered) return;
  _registered = true;

  for (final name in const [
    'workspace.getState',
    'workspace.getCurrentScene',
    'workspace.getBuildHierarchy',
    'workspace.getRuntimeHierarchy',
    'workspace.getDiagnostics',
    'workspace.getPreviewLogs',
    'workspace.getSyncStatus',
  ]) {
    registerMarionetteExtension(
      name: name,
      description: 'Read a compact Flame Workspace development snapshot.',
      inputSchema: const ExtensionInputSchema(),
      callback: (_) => _guard(name, () => _read(name)),
    );
  }

  registerMarionetteExtension(
    name: 'workspace.openFixture',
    description: 'Open a temporary copy of the modern Workspace fixture.',
    inputSchema: const ExtensionInputSchema(),
    callback: (_) => _guard('workspace.openFixture', _openFixture),
  );

  registerMarionetteExtension(
    name: 'workspace.selectScene',
    description: 'Select an existing scene in Build State for test setup.',
    inputSchema: const ExtensionInputSchema(
      properties: {
        'sceneId': ExtensionParam.string(
          title: 'Scene ID',
          description: 'Stable semantic scene ID.',
        ),
      },
      required: ['sceneId'],
    ),
    callback: (parameters) =>
        _guard('workspace.selectScene', () => _selectScene(parameters)),
  );
}

/// Makes the currently visible Workbench available to the read-only tools.
void attachWorkspaceMarionetteContext(
  FlameProjectState state,
  FlameProjectRunner runner,
) {
  if (!kDebugMode) return;
  _state = state;
  _runner = runner;
  if (_mountHandshake.acknowledge(state.project.location.path)) {
    _openingProjectPath = null;
  }
}

void detachWorkspaceMarionetteContext(FlameProjectState state) {
  if (identical(_state, state)) {
    _state = null;
    _runner = null;
  }
}

Future<MarionetteExtensionResult> _guard(
  String operation,
  Future<MarionetteExtensionResult> Function() callback,
) async {
  try {
    return await callback();
  } catch (error, stackTrace) {
    debugPrint('$operation failed: $error\\n$stackTrace');
    return MarionetteExtensionResult.error(1, '$operation failed: $error');
  }
}

@visibleForTesting
Future<MarionetteExtensionResult> readWorkspaceMarionetteToolForTesting(
  String name,
) => _read(name);

Future<MarionetteExtensionResult> _read(String name) async {
  final openingPath = _openingProjectPath;
  if (openingPath != null && name == 'workspace.getState') {
    return MarionetteExtensionResult.success({
      'screen': 'openingProject',
      'projectOpen': false,
      'targetProjectPath': openingPath,
      'navigatorAvailable': _navigatorKey?.currentState != null,
      'workbenchAttached': _state != null,
    });
  }
  final state = _state;
  final runner = _runner;
  if (state == null || runner == null) {
    final data = switch (name) {
      'workspace.getState' => <String, Object?>{
        'screen': 'welcome',
        'projectOpen': false,
      },
      'workspace.getCurrentScene' ||
      'workspace.getBuildHierarchy' ||
      'workspace.getRuntimeHierarchy' ||
      'workspace.getSyncStatus' => {'available': false, 'reason': 'no_project'},
      'workspace.getDiagnostics' => {
        'available': true,
        'project': <Object?>[],
        'runtime': <Object?>[],
        'runner': <Object?>[],
      },
      'workspace.getPreviewLogs' => {'available': true, 'logs': <String>[]},
      _ => <String, Object?>{},
    };
    return MarionetteExtensionResult.success(data);
  }

  final data = switch (name) {
    'workspace.getState' => {
      ..._stateSnapshot(state, runner),
      'initialized': state.initialized,
      'projectPath': path.normalize(path.absolute(state.project.location.path)),
      'projectName': state.project.name,
    },
    'workspace.getCurrentScene' => _sceneSnapshot(state.currentScene),
    'workspace.getBuildHierarchy' => {
      'sceneId': state.currentScene.id,
      'sceneName': state.currentScene.name,
      'components': [
        for (final component in state.currentScene.components)
          _buildNode(component),
      ],
    },
    'workspace.getRuntimeHierarchy' => {
      'available': state.runtimeTree != null,
      if (state.runtimeTree case final tree?) 'tree': _runtimeNode(tree),
    },
    'workspace.getDiagnostics' => {
      'project': [
        for (final diagnostic in state.projectDiagnostics)
          _diagnostic(diagnostic),
      ],
      'runtime': [
        for (final diagnostic in state.runtimeTreeDiagnostics)
          _runtimeDiagnostic(diagnostic),
      ],
      'runner': [
        if (runner.runtimeDiagnostic case final diagnostic?)
          _diagnostic(diagnostic),
        if (runner.executionDiagnostic case final diagnostic?)
          _diagnostic(diagnostic),
      ],
    },
    'workspace.getPreviewLogs' => {
      'logs': runner.logs.length <= 100
          ? List<String>.of(runner.logs)
          : runner.logs.sublist(runner.logs.length - 100),
    },
    'workspace.getSyncStatus' => {
      'mode': state.executionMode.name,
      'runtimeConnected': runner.canControlRuntime,
      'connectionState': runner.connectionState.name,
      'runtimeSessionId': runner.runtimeSessionId,
      'runtimeTreeAvailable': state.runtimeTree != null,
      'diagnostics': [
        for (final diagnostic in state.runtimeTreeDiagnostics)
          _runtimeDiagnostic(diagnostic),
      ],
    },
    _ => <String, Object?>{},
  };
  return MarionetteExtensionResult.success(data);
}

Future<MarionetteExtensionResult> _openFixture() async {
  if (_openingFixture) {
    throw StateError('A fixture project is already being opened.');
  }
  _openingFixture = true;
  try {
    return await _prepareAndOpenFixture();
  } finally {
    _openingFixture = false;
  }
}

Future<MarionetteExtensionResult> _prepareAndOpenFixture() async {
  final navigator = _navigatorKey?.currentState;
  if (navigator == null) {
    return const MarionetteExtensionResult.error(
      1,
      'Workspace navigator is not ready.',
    );
  }
  final source = Directory('../template').absolute;
  final temporary = await Directory.systemTemp.createTemp(
    'flame_workspace_smoke_',
  );
  await _copyDirectory(source, temporary);
  final entrypoint = File(path.join(temporary.path, 'lib', 'main.dart'));
  if (!await entrypoint.exists()) {
    throw StateError(
      'Runnable smoke project is missing lib/main.dart: ${temporary.path}',
    );
  }
  final pubspec = File(path.join(temporary.path, 'pubspec.yaml'));
  final runtimePackage = Directory('../flame_workspace_runtime').absolute;
  final pubspecSource = await pubspec.readAsString();
  await pubspec.writeAsString(
    pubspecSource
        .replaceFirst('resolution: workspace\n', '')
        .replaceFirst(
          "path: '../flame_workspace_runtime'",
          "path: '${runtimePackage.path}'",
        ),
  );
  final pubGet = await Process.run('flutter', const [
    'pub',
    'get',
  ], workingDirectory: temporary.path);
  if (pubGet.exitCode != 0) {
    throw StateError('Fixture dependency resolution failed: ${pubGet.stderr}');
  }
  if (_mountHandshake.isPending) {
    throw StateError('A Workbench navigation is already pending.');
  }
  final project = await ProjectImporter.import(temporary);
  final projectPath = path.normalize(path.absolute(project.location.path));
  _openingProjectPath = projectPath;
  try {
    final mounted = _mountHandshake.waitFor(
      projectPath,
      timeout: _mountTimeout,
    );
    if (!await WorkspaceNavigation.openProject(project)) {
      throw StateError(
        'Cannot switch projects until authored changes are saved.',
      );
    }
    await mounted;
  } on TimeoutException {
    throw StateError(
      'Workbench mount timed out for $projectPath '
      '(navigatorAvailable: ${_navigatorKey?.currentState != null}, '
      'workbenchAttached: ${_state != null}).',
    );
  } finally {
    _openingProjectPath = null;
  }
  final state = _state;
  if (state == null ||
      path.normalize(path.absolute(state.project.location.path)) !=
          projectPath) {
    throw StateError(
      'Workbench mounted for an unexpected project after opening $projectPath.',
    );
  }
  return MarionetteExtensionResult.success({
    'opened': true,
    'initialized': state.initialized,
    'projectName': project.name,
    'projectPath': projectPath,
  });
}

Future<void> _copyDirectory(Directory source, Directory target) async {
  await for (final entity in source.list(followLinks: false)) {
    if (entity is Directory &&
        const {
          '.dart_tool',
          '.git',
          'build',
        }.contains(path.basename(entity.path))) {
      continue;
    }
    final destination = path.join(target.path, path.basename(entity.path));
    if (entity is Directory) {
      final child = Directory(destination);
      await child.create(recursive: true);
      await _copyDirectory(entity, child);
    } else if (entity is File) {
      await entity.copy(destination);
    }
  }
}

Future<MarionetteExtensionResult> _selectScene(
  Map<String, String> parameters,
) async {
  final state = _state;
  if (state == null) {
    return const MarionetteExtensionResult.success({
      'available': false,
      'reason': 'no_project',
    });
  }
  final sceneId = parameters['sceneId'];
  if (sceneId == null ||
      !state.workspaceProject.scenes.any((scene) => scene.id == sceneId)) {
    return const MarionetteExtensionResult.invalidParams(
      'sceneId must identify an existing scene.',
    );
  }
  state.editWorkspaceScene(sceneId);
  return MarionetteExtensionResult.success(_sceneSnapshot(state.currentScene));
}

Map<String, Object?> _stateSnapshot(
  FlameProjectState state,
  FlameProjectRunner runner,
) => {
  'screen': 'workbench',
  'projectOpen': true,
  'executionMode': state.executionMode.name,
  'dirty': state.isDirty,
  'selectedScene': _sceneSnapshot(state.currentScene),
  'selectedComponent': ?_componentReference(state.selectedComponent),
  'previewState': runner.previewState.name,
  'previewRunning': runner.isPreviewRunning,
  'runtimeConnected': runner.canControlRuntime,
  'componentSupportReport': ComponentSupportReport.fromCatalog(
    state.flameComponents,
  ).toJson(),
};

Map<String, Object?> _sceneSnapshot(SceneDefinition scene) => {
  'id': scene.id,
  'name': scene.name,
  'backgroundColor': scene.backgroundColor,
  'componentCount': _componentCount(scene.components),
};

Map<String, Object?>? _componentReference(ComponentInstance? component) {
  if (component == null) return null;
  return {'id': component.id, 'type': component.type.name};
}

Map<String, Object?> _buildNode(ComponentInstance component) => {
  'id': component.id,
  'type': component.type.name,
  'children': [for (final child in component.children) _buildNode(child)],
};

Map<String, Object?> _runtimeNode(WorkspaceComponentNode node) => {
  'id': node.id,
  'type': node.type,
  'children': [for (final child in node.children) _runtimeNode(child)],
};

Map<String, Object?> _diagnostic(WorkspaceDiagnostic diagnostic) => {
  'category': diagnostic.category.name,
  'code': diagnostic.code,
  'operation': diagnostic.operation,
  'message': diagnostic.message,
  ...switch (diagnostic.recovery) {
    final recovery? => {'recovery': recovery},
    _ => const <String, Object?>{},
  },
};

Map<String, Object?> _runtimeDiagnostic(RuntimeTreeDiagnostic diagnostic) => {
  'kind': diagnostic.kind.name,
  ...switch (diagnostic.componentId) {
    final id? => {'componentId': id},
    _ => const <String, Object?>{},
  },
  'message': diagnostic.message,
};

int _componentCount(Iterable<ComponentInstance> components) => components.fold(
  0,
  (count, component) => count + 1 + _componentCount(component.children),
);
