import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/parser/type_resolver.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';

class WorkspaceModelMapper {
  const WorkspaceModelMapper._();

  static WorkspaceProject fromIndexed(
    IndexedProject indexed, {
    required FlameTypeResolver resolver,
    String? projectName,
  }) {
    final components = ProjectIndexer.componentsFrom(
      indexed,
      resolver: resolver,
    ).toList()..sort(_compareComponents);
    final scenes = ProjectIndexer.scenesFrom(
      indexed,
      resolver: resolver,
    ).toList();
    final semanticScenes = <SceneDefinition>[];

    if (scenes.isEmpty) {
      final sourcePath = components.isEmpty
          ? null
          : components.first.$2['source'] as String?;
      final sceneId = WorkspaceIds.scene(
        sourcePath: sourcePath ?? projectName ?? 'main',
        name: 'Main',
      );
      semanticScenes.add(
        SceneDefinition(
          id: sceneId,
          name: 'Main',
          sourcePath: sourcePath,
          components: _mapComponents(components, sceneId),
        ),
      );
    } else {
      for (final scene in scenes) {
        final sceneId = WorkspaceIds.scene(
          sourcePath: scene.$1.filePath,
          name: scene.$1.name,
        );
        semanticScenes.add(
          SceneDefinition(
            id: sceneId,
            name: scene.$1.name,
            sourcePath: scene.$1.filePath,
            components: _mapComponents(
              components
                  .where(
                    (component) => component.$2['source'] == scene.$1.filePath,
                  )
                  .toList(),
              sceneId,
            ),
          ),
        );
      }
    }

    return WorkspaceProject(
      id: 'project:${projectName ?? 'workspace'}',
      name: projectName ?? 'Workspace Project',
      scenes: semanticScenes,
    );
  }

  static int _compareComponents(
    IndexedComponent first,
    IndexedComponent second,
  ) {
    final firstPath = first.$1.filePath ?? '';
    final secondPath = second.$1.filePath ?? '';
    final pathComparison = firstPath.compareTo(secondPath);
    if (pathComparison != 0) return pathComparison;
    return first.$1.name.compareTo(second.$1.name);
  }

  static List<ComponentInstance> _mapComponents(
    Iterable<IndexedComponent> indexedComponents,
    String sceneId,
  ) {
    var ordinal = 0;
    return indexedComponents.map((indexedComponent) {
      return _mapComponent(indexedComponent.$1, sceneId, ordinal++);
    }).toList();
  }

  static ComponentInstance _mapComponent(
    FlameComponentObject component,
    String sceneId,
    int ordinal,
  ) {
    final properties = <String, Object?>{};
    for (final parameter in component.parameters) {
      properties[parameter.name] = parameter.defaultValue;
    }

    return ComponentInstance(
      id: WorkspaceIds.component(
        sceneId: sceneId,
        name: component.declarationName ?? component.name,
        ordinal: ordinal,
      ),
      type: ComponentType(id: component.type, name: component.type),
      declarationName: component.declarationName ?? component.name,
      sourcePath: component.filePath,
      properties: properties,
      children: component.components.indexed.map((entry) {
        return _mapComponent(entry.$2, sceneId, ordinal + entry.$1 + 1);
      }),
    );
  }
}
