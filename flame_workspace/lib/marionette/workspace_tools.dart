import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:flame_workspace_protocol/runtime.dart';

import '../workbench/model/runtime_tree_reconciliation.dart';
import '../workbench/model/semantic_model.dart';
import '../workbench/model/workspace_diagnostic.dart';
import '../workbench/parser/component_capabilities.dart';

import '../workbench/runner/runner.dart';
import '../workbench/runner/state.dart';

FlameProjectState? _state;
FlameProjectRunner? _runner;
var _registered = false;

/// Registers the small, read-oriented Marionette API used to inspect the
/// Workspace during development and integration tests.
///
/// The extensions intentionally do not expose generic model or runtime
/// mutation. Normal editor workflows must still be exercised through the UI.
void initializeWorkspaceMarionetteTools() {
  if (!kDebugMode || _registered) return;
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
      callback: (_) async => _read(name),
    );
  }

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
    callback: _selectScene,
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
}

void detachWorkspaceMarionetteContext(FlameProjectState state) {
  if (identical(_state, state)) {
    _state = null;
    _runner = null;
  }
}

Future<MarionetteExtensionResult> _read(String name) async {
  final state = _state;
  final runner = _runner;
  if (state == null || runner == null) {
    return const MarionetteExtensionResult.error(
      1,
      'No Flame Workspace project is currently open.',
    );
  }

  final data = switch (name) {
    'workspace.getState' => _stateSnapshot(state, runner),
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

Future<MarionetteExtensionResult> _selectScene(
  Map<String, String> parameters,
) async {
  final state = _state;
  if (state == null) {
    return const MarionetteExtensionResult.error(
      1,
      'No Flame Workspace project is currently open.',
    );
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
