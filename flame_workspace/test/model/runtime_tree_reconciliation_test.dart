import 'package:flame_workspace/workbench/model/runtime_tree_reconciliation.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const type = ComponentType(id: 'sprite', name: 'SpriteComponent');
  final child = ComponentInstance(id: 'child', type: type);
  final parent = ComponentInstance(id: 'parent', type: type, children: [child]);
  final scene = SceneDefinition(
    id: 'scene-id',
    name: 'level',
    components: [parent],
  );

  test('accepts a matching nested runtime tree', () {
    final diagnostics = reconcileRuntimeTree(
      expectedScene: scene,
      runtimeRoot: const WorkspaceComponentNode(
        id: 'level',
        type: 'LevelScene',
        children: [
          WorkspaceComponentNode(
            id: 'parent',
            type: 'SpriteComponent',
            children: [
              WorkspaceComponentNode(id: 'child', type: 'SpriteComponent'),
            ],
          ),
        ],
      ),
    );

    expect(diagnostics, isEmpty);
  });

  test(
    'does not reconcile calculated TextComponent size as authored resize',
    () {
      final textScene = SceneDefinition(
        id: 'text-scene',
        name: 'text-level',
        components: [
          ComponentInstance(
            id: 'label',
            type: const ComponentType(id: 'text', name: 'TextComponent'),
          ),
        ],
      );
      final diagnostics = reconcileRuntimeTree(
        expectedScene: textScene,
        runtimeRoot: const WorkspaceComponentNode(
          id: 'text-level',
          type: 'TextLevel',
          children: [
            WorkspaceComponentNode(
              id: 'label',
              type: 'TextComponent',
              transform: WorkspaceTransformData(size: {'x': 96, 'y': 28}),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
      expect(
        textScene.components.single.transform.size,
        WorkspaceVector2.zero(),
      );
    },
  );

  test('reports a dynamically spawned runtime-only child', () {
    const runtimeOnlyId = 'spawned-enemy';
    final diagnostics = reconcileRuntimeTree(
      expectedScene: scene,
      runtimeRoot: const WorkspaceComponentNode(
        id: 'level',
        type: 'LevelScene',
        children: [
          WorkspaceComponentNode(
            id: 'parent',
            type: 'SpriteComponent',
            children: [
              WorkspaceComponentNode(id: runtimeOnlyId, type: 'EnemyComponent'),
            ],
          ),
        ],
      ),
    );

    final unexpected = diagnostics.singleWhere(
      (diagnostic) =>
          diagnostic.kind == RuntimeTreeDiagnosticKind.unexpectedComponent,
    );
    expect(unexpected.componentId, runtimeOnlyId);
    expect(unexpected.diagnostic.code, 'runtime_tree_unexpectedComponent');
    expect(unexpected.displayMessage, contains('synchronization['));
    expect(unexpected.displayMessage, contains('refresh to confirm'));
  });

  test('reports missing, runtime-only, type and parent mismatches', () {
    final diagnostics = reconcileRuntimeTree(
      expectedScene: scene,
      runtimeRoot: const WorkspaceComponentNode(
        id: 'level',
        type: 'LevelScene',
        children: [
          WorkspaceComponentNode(id: 'child', type: 'WrongComponent'),
          WorkspaceComponentNode(id: 'runtime-only', type: 'ExtraComponent'),
        ],
      ),
    );

    expect(
      diagnostics.map((diagnostic) => diagnostic.kind),
      containsAll([
        RuntimeTreeDiagnosticKind.missingComponent,
        RuntimeTreeDiagnosticKind.unexpectedComponent,
        RuntimeTreeDiagnosticKind.typeMismatch,
        RuntimeTreeDiagnosticKind.parentMismatch,
      ]),
    );
  });

  test('reports duplicate runtime ids and unknown scenes', () {
    final duplicates = reconcileRuntimeTree(
      expectedScene: scene,
      runtimeRoot: const WorkspaceComponentNode(
        id: 'level',
        type: 'LevelScene',
        children: [
          WorkspaceComponentNode(id: 'duplicate', type: 'A'),
          WorkspaceComponentNode(id: 'duplicate', type: 'B'),
        ],
      ),
    );
    expect(
      duplicates.map((diagnostic) => diagnostic.kind),
      contains(RuntimeTreeDiagnosticKind.duplicateId),
    );

    final unknown = reconcileRuntimeTree(
      expectedScene: null,
      runtimeRoot: const WorkspaceComponentNode(
        id: 'other',
        type: 'OtherScene',
      ),
    );
    expect(unknown.single.kind, RuntimeTreeDiagnosticKind.unknownScene);
  });
}
