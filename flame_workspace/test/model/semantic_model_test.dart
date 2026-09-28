import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('constructs a scene with a component hierarchy', () {
    final child = ComponentInstance(
      id: 'child',
      type: const ComponentType(id: 'sprite', name: 'SpriteComponent'),
    );
    final parent = ComponentInstance(
      id: 'parent',
      type: const ComponentType(id: 'player', name: 'Player'),
      children: [child],
    );
    final scene = SceneDefinition(
      id: 'scene',
      name: 'Main',
      components: [parent],
    );
    final project = WorkspaceProject(
      id: 'project',
      name: 'Game',
      scenes: [scene],
    );

    expect(
      project.scenes.single.components.single.children.single,
      same(child),
    );
    expect(project.toJson()['scenes'], hasLength(1));
  });

  test('updates component properties and transforms', () {
    final component = ComponentInstance(
      id: 'player',
      type: const ComponentType(id: 'player', name: 'Player'),
    );
    final transform = const WorkspaceTransform(
      position: WorkspaceVector2(10, 20),
      size: WorkspaceVector2(32, 48),
      angle: 0.5,
    );

    component.setProperty('speed', 4);
    component.setTransform(transform);

    expect(component.properties['speed'], 4);
    expect(component.transform.position, const WorkspaceVector2(10, 20));
    expect(component.transform.angle, 0.5);
  });

  test('generates stable identifiers for the same semantic source', () {
    final firstScene = WorkspaceIds.scene(
      sourcePath: 'lib/main.dart',
      name: 'Main',
    );
    final secondScene = WorkspaceIds.scene(
      sourcePath: 'lib/main.dart',
      name: 'Main',
    );

    expect(firstScene, secondScene);
    expect(
      WorkspaceIds.component(sceneId: firstScene, name: 'Player', ordinal: 0),
      WorkspaceIds.component(sceneId: secondScene, name: 'Player', ordinal: 0),
    );
  });
}
