import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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
    final scenes = ProjectIndexer.scenesFrom(indexed, resolver: resolver);
    final semanticScenes = <SceneDefinition>[];
    for (final sceneResult in scenes) {
      final (scene, _, _) = sceneResult;
      final script = scene.script;
      final scriptIsPart =
          script?.unit.$2.directives.any(
            (directive) => directive is PartOfDirective,
          ) ??
          false;
      final sceneId = WorkspaceIds.scene(
        sourcePath: scene.filePath,
        name: scene.sceneName,
      );
      semanticScenes.add(
        SceneDefinition(
          id: sceneId,
          name: scene.sceneName,
          sourcePath: scene.filePath,
          runtimeClassName: script?.name ?? scene.name,
          runtimeSourcePath: script == null || scriptIsPart
              ? scene.filePath
              : script.filePath,
          components: _mapComponents(scene.components, sceneId),
        ),
      );
    }

    return WorkspaceProject(
      id: 'project:${projectName ?? 'workspace'}',
      name: projectName ?? 'Workspace Project',
      scenes: semanticScenes,
    );
  }

  static WorkspaceModelMappingResult inspectForMigration(
    IndexedProject indexed, {
    required FlameTypeResolver resolver,
    String? projectName,
  }) {
    final components = ProjectIndexer.componentsFrom(
      indexed,
      resolver: resolver,
    ).toList();
    final scenes = ProjectIndexer.scenesFrom(indexed, resolver: resolver);
    final diagnostics = <String>[];

    if (scenes.isEmpty) {
      diagnostics.add(
        'No statically declared FlameScene was found. Scene composition cannot be inferred safely.',
      );
    }

    for (final (scene, _, unit) in scenes) {
      if (scene.components.isEmpty && components.isNotEmpty) {
        diagnostics.add(
          'Scene "${scene.sceneName}" has no typed component fields, while Flame components exist in the project. Its composition may be dynamic.',
        );
      }
      final knownFields = scene.components
          .map((component) => component.declarationName)
          .whereType<String>()
          .toSet();
      final declaration = unit.declarations
          .whereType<ClassDeclaration>()
          .where(
            (declaration) => declaration.namePart.typeName.lexeme == scene.name,
          )
          .firstOrNull;
      final onLoad = declaration == null || declaration.body is! BlockClassBody
          ? null
          : (declaration.body as BlockClassBody).members
                .whereType<MethodDeclaration>()
                .where((method) => method.name.lexeme == 'onLoad')
                .firstOrNull;
      if (onLoad != null) {
        final visitor = _SceneCompositionVisitor(knownFields);
        onLoad.accept(visitor);
        if (visitor.hasUnmappedComposition) {
          diagnostics.add(
            'Scene "${scene.sceneName}" adds components dynamically in onLoad; migrate it to explicit typed scene fields first.',
          );
        }
      }
    }

    return WorkspaceModelMappingResult(
      project: diagnostics.isEmpty
          ? fromIndexed(indexed, resolver: resolver, projectName: projectName)
          : null,
      diagnostics: diagnostics,
    );
  }

  static List<ComponentInstance> _mapComponents(
    Iterable<FlameComponentObject> components,
    String sceneId,
  ) {
    var ordinal = 0;
    return components
        .map((component) => _mapComponent(component, sceneId, ordinal++))
        .toList();
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

class WorkspaceModelMappingResult {
  const WorkspaceModelMappingResult({
    required this.project,
    required this.diagnostics,
  });

  final WorkspaceProject? project;
  final List<String> diagnostics;

  bool get canMigrate => project != null && diagnostics.isEmpty;
}

class _SceneCompositionVisitor extends RecursiveAstVisitor<void> {
  _SceneCompositionVisitor(this.knownFields);

  final Set<String> knownFields;
  bool hasUnmappedComposition = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'add') {
      final arguments = node.argumentList.arguments;
      if (arguments.length != 1 ||
          arguments.single is! SimpleIdentifier ||
          !knownFields.contains((arguments.single as SimpleIdentifier).name)) {
        hasUnmappedComposition = true;
      }
    } else if (methodName == 'addAll' ||
        (node.target == null && methodName != 'onLoad') ||
        node.target is ThisExpression) {
      hasUnmappedComposition = true;
    }
    super.visitMethodInvocation(node);
  }
}
