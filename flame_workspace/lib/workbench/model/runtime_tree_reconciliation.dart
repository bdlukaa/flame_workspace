import 'package:flame_workspace_protocol/runtime.dart';

import 'semantic_model.dart';
import 'workspace_diagnostic.dart';

enum RuntimeTreeDiagnosticKind {
  missingComponent,
  unexpectedComponent,
  typeMismatch,
  duplicateId,
  parentMismatch,
  unknownScene,
  unavailable,
}

class RuntimeTreeDiagnostic {
  const RuntimeTreeDiagnostic({
    required this.kind,
    required this.message,
    this.componentId,
  });

  final RuntimeTreeDiagnosticKind kind;
  final String message;
  final String? componentId;

  WorkspaceDiagnostic get diagnostic => WorkspaceDiagnostic(
    category: WorkspaceDiagnosticCategory.synchronization,
    code: 'runtime_tree_${kind.name}',
    operation: 'Reconcile runtime scene',
    message: message,
    recovery: switch (kind) {
      RuntimeTreeDiagnosticKind.missingComponent ||
      RuntimeTreeDiagnosticKind.typeMismatch ||
      RuntimeTreeDiagnosticKind.parentMismatch =>
        'Save and regenerate the scene, then recreate the running scene.',
      RuntimeTreeDiagnosticKind.unexpectedComponent => 'Runtime-only components may be created by game logic; refresh to confirm the current tree.',
      RuntimeTreeDiagnosticKind.duplicateId =>
        'Ensure every authored component has a unique semantic ID.',
      RuntimeTreeDiagnosticKind.unknownScene =>
        'Select a scene registered in this Workspace project.',
      RuntimeTreeDiagnosticKind.unavailable =>
        'Reconnect to VM Service and refresh the runtime hierarchy.',
    },
  );

  String get displayMessage => diagnostic.displayMessage;
}

List<RuntimeTreeDiagnostic> reconcileRuntimeTree({
  required SceneDefinition? expectedScene,
  required WorkspaceComponentNode runtimeRoot,
}) {
  if (expectedScene == null) {
    return [
      RuntimeTreeDiagnostic(
        kind: RuntimeTreeDiagnosticKind.unknownScene,
        message: 'Runtime scene "${runtimeRoot.id}" is not in this project.',
      ),
    ];
  }

  final diagnostics = <RuntimeTreeDiagnostic>[];
  final expected =
      <String, ({ComponentInstance component, String? parentId})>{};
  void indexExpected(ComponentInstance component, String? parentId) {
    expected[component.id] = (component: component, parentId: parentId);
    for (final child in component.children) {
      indexExpected(child, component.id);
    }
  }

  for (final component in expectedScene.components) {
    indexExpected(component, null);
  }

  final runtime = <String, ({WorkspaceComponentNode node, String? parentId})>{};
  final duplicateIds = <String>{};
  void indexRuntime(
    WorkspaceComponentNode node,
    String? parentId, {
    bool root = false,
  }) {
    if (!root) {
      if (runtime.containsKey(node.id)) {
        duplicateIds.add(node.id);
      } else {
        runtime[node.id] = (node: node, parentId: parentId);
      }
    }
    for (final child in node.children) {
      indexRuntime(child, root ? null : node.id, root: false);
    }
  }

  indexRuntime(runtimeRoot, null, root: true);

  for (final id in duplicateIds) {
    diagnostics.add(
      RuntimeTreeDiagnostic(
        kind: RuntimeTreeDiagnosticKind.duplicateId,
        componentId: id,
        message: 'Runtime component ID "$id" occurs more than once.',
      ),
    );
  }

  for (final entry in expected.entries) {
    final actual = runtime[entry.key];
    if (actual == null) {
      diagnostics.add(
        RuntimeTreeDiagnostic(
          kind: RuntimeTreeDiagnosticKind.missingComponent,
          componentId: entry.key,
          message: 'Expected component "${entry.key}" is missing at runtime.',
        ),
      );
      continue;
    }
    final expectedComponent = entry.value.component;
    if (actual.node.type != expectedComponent.type.name) {
      diagnostics.add(
        RuntimeTreeDiagnostic(
          kind: RuntimeTreeDiagnosticKind.typeMismatch,
          componentId: entry.key,
          message:
              'Component "${entry.key}" has runtime type '
              '"${actual.node.type}"; expected "${expectedComponent.type.name}".',
        ),
      );
    }
    if (actual.parentId != entry.value.parentId) {
      diagnostics.add(
        RuntimeTreeDiagnostic(
          kind: RuntimeTreeDiagnosticKind.parentMismatch,
          componentId: entry.key,
          message:
              'Component "${entry.key}" has runtime parent '
              '"${actual.parentId ?? 'scene root'}"; expected '
              '"${entry.value.parentId ?? 'scene root'}".',
        ),
      );
    }
  }

  for (final entry in runtime.entries) {
    if (!expected.containsKey(entry.key)) {
      diagnostics.add(
        RuntimeTreeDiagnostic(
          kind: RuntimeTreeDiagnosticKind.unexpectedComponent,
          componentId: entry.key,
          message:
              'Runtime-only component "${entry.key}" is not in Build State.',
        ),
      );
    }
  }

  return diagnostics;
}
