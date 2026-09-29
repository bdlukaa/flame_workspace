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
          : (() {
              final (_, indexedUnit, _) = components.first;
              return indexedUnit['source'] as String?;
            })();
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
      for (final sceneResult in scenes) {
        final (scene, _, _) = sceneResult;
        final sceneId = WorkspaceIds.scene(
          sourcePath: scene.filePath,
          name: scene.sceneName,
        );
        semanticScenes.add(
          SceneDefinition(
            id: sceneId,
            name: scene.sceneName,
            sourcePath: scene.filePath,
            components: _mapComponents(
              components.where((component) {
                final (_, indexedUnit, _) = component;
                return indexedUnit['source'] == scene.filePath;
              }).toList(),
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
    final (firstComponent, _, _) = first;
    final (secondComponent, _, _) = second;
    final firstPath = firstComponent.filePath ?? '';
    final secondPath = secondComponent.filePath ?? '';
    final pathComparison = firstPath.compareTo(secondPath);
    if (pathComparison != 0) return pathComparison;
    return firstComponent.name.compareTo(secondComponent.name);
  }

  static List<ComponentInstance> _mapComponents(
    Iterable<IndexedComponent> indexedComponents,
    String sceneId,
  ) {
    var ordinal = 0;
    return indexedComponents.map((indexedComponent) {
      final (component, _, _) = indexedComponent;
      return _mapComponent(component, sceneId, ordinal++);
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

    final propertyDefinitions = component.parameters
        .map(
          (parameter) => WorkspacePropertyDefinition(
            name: parameter.name,
            type: parameter.type,
            defaultValue: parameter.defaultValue,
            inherited: parameter.superComponents?.isNotEmpty ?? false,
            editable:
                (parameter.isLocalField && !parameter.isFinalField) ||
                parameter.hasSetter,
            enumValues: parameter.enumValues,
          ),
        )
        .toList();

    return ComponentInstance(
      id: WorkspaceIds.component(
        sceneId: sceneId,
        name: component.declarationName ?? component.name,
        ordinal: ordinal,
      ),
      type: ComponentType(
        id: component.name,
        name: component.name,
        baseType: component.type,
        isPositionComponent: component.parameters.any(
          (parameter) =>
              parameter.superComponents?.contains('PositionComponent') ?? false,
        ),
        properties: propertyDefinitions,
      ),
      declarationName: component.declarationName ?? component.name,
      sourcePath: component.filePath,
      properties: properties,
      children: component.components.indexed.map((entry) {
        final (childOrdinal, childComponent) = entry;
        return _mapComponent(
          childComponent,
          sceneId,
          ordinal + childOrdinal + 1,
        );
      }),
    );
  }
}
