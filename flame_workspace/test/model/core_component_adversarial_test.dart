import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_persistence_generator.dart';
import 'package:flame_workspace/workbench/model/scene_persistence.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Tier 1 edge values remain typed through persistence and generation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_core_adversarial_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = FlameProject(
        name: 'edge_values',
        organization: 'test',
        location: directory,
        initialScene: 'Edges',
      );
      final edgePaint = const WorkspacePaint(
        color: WorkspaceColor(0x00000000),
        style: WorkspacePaintStyle.stroke,
        strokeWidth: 10000,
        strokeCap: WorkspaceStrokeCap.round,
        strokeJoin: WorkspaceStrokeJoin.bevel,
      );
      final transform = const WorkspaceTransform(
        position: WorkspaceVector2(-12.5, 0),
        size: WorkspaceVector2(0, -4.25),
        scale: WorkspaceVector2(0.25, 2.5),
        angle: -1.75,
        anchor: WorkspaceVector2(0.25, 0.75),
      );
      final scene = SceneDefinition(
        id: 'scene:edges',
        name: 'Edges',
        components: [
          ComponentInstance(
            id: 'scene:edges:circle',
            type: const ComponentType(
              id: 'CircleComponent',
              name: 'CircleComponent',
              baseType: 'ShapeComponent',
              isPositionComponent: true,
              properties: [
                WorkspacePropertyDefinition(name: 'radius', type: 'double?'),
                WorkspacePropertyDefinition(name: 'paint', type: 'Paint?'),
              ],
            ),
            properties: {'radius': -0.5, 'paint': edgePaint},
            transform: transform,
          ),
          ComponentInstance(
            id: 'scene:edges:rectangle',
            type: const ComponentType(
              id: 'RectangleComponent',
              name: 'RectangleComponent',
              baseType: 'ShapeComponent',
              isPositionComponent: true,
              properties: [
                WorkspacePropertyDefinition(name: 'paint', type: 'Paint?'),
              ],
            ),
            properties: {'paint': edgePaint},
            transform: transform,
          ),
          ComponentInstance(
            id: 'scene:edges:polygon',
            type: const ComponentType(
              id: 'PolygonComponent',
              name: 'PolygonComponent',
              baseType: 'ShapeComponent',
              isPositionComponent: true,
              properties: [
                WorkspacePropertyDefinition(
                  name: 'vertices',
                  type: 'List<Vector2>',
                  constructorPosition: 0,
                ),
                WorkspacePropertyDefinition(name: 'paint', type: 'Paint?'),
              ],
            ),
            properties: {
              'vertices': const [
                WorkspaceVectorValue(-1.5, 0.25),
                WorkspaceVectorValue(0, 0),
                WorkspaceVectorValue(2.75, -3.5),
              ],
              'paint': edgePaint,
            },
            transform: transform,
          ),
          ComponentInstance(
            id: 'scene:edges:text',
            type: const ComponentType(
              id: 'TextComponent',
              name: 'TextComponent',
              baseType: 'PositionComponent',
              isPositionComponent: true,
              properties: [
                WorkspacePropertyDefinition(name: 'text', type: 'String'),
                WorkspacePropertyDefinition(
                  name: 'textRenderer',
                  type: 'TextPaint?',
                ),
              ],
            ),
            properties: {
              'text': '"quoted"\nnext',
              'textRenderer': const WorkspaceTextPaint(
                color: WorkspaceColor(0x00000000),
                fontSize: 0,
                fontFamily: '',
                fontWeight: WorkspaceFontWeight.w700,
                fontStyle: WorkspaceFontStyle.italic,
              ),
            },
            transform: transform,
          ),
          ComponentInstance(
            id: 'scene:edges:text-box',
            type: const ComponentType(
              id: 'TextBoxComponent',
              name: 'TextBoxComponent',
              baseType: 'TextComponent',
              isPositionComponent: true,
              properties: [
                WorkspacePropertyDefinition(name: 'text', type: 'String'),
                WorkspacePropertyDefinition(
                  name: 'textRenderer',
                  type: 'TextPaint?',
                ),
                WorkspacePropertyDefinition(
                  name: 'boxConfig',
                  type: 'TextBoxConfig',
                ),
                WorkspacePropertyDefinition(name: 'align', type: 'Anchor'),
              ],
            ),
            properties: {
              'text': '',
              'textRenderer': const WorkspaceTextPaint(fontSize: 0),
              'boxConfig': const WorkspaceTextBoxConfig(
                maxWidth: 0.01,
                margins: WorkspaceEdgeInsets(
                  top: 1,
                  right: 2.5,
                  bottom: 0,
                  left: 4,
                ),
                timePerChar: 0,
                dismissDelay: 0,
                growingBox: true,
              ),
              'align': const WorkspaceAnchor(0.25, 0.75),
            },
            transform: transform,
          ),
        ],
      );

      final file = WorkspaceScenePersistence.fileFor(project, scene);
      await WorkspaceScenePersistence.save(file: file, scene: scene);
      final reopened = await WorkspaceScenePersistence.load(file);
      final generated = ScenePersistenceGenerator.generate(reopened, project);

      expect(generated, contains('createWorkspaceComponentJson'));
      expect(generated, contains('"radius":-0.5'));
      expect(generated, contains('"strokeWidth":10000.0'));
      expect(generated, contains('"position":{"x":-12.5,"y":0.0}'));
      expect(generated, contains('"scale":{"x":0.25,"y":2.5}'));
      expect(generated, contains('"anchor":{"x":0.25,"y":0.75}'));
      expect(generated, contains('quoted'));
      expect(generated, contains('"fontFamily":""'));
      expect(generated, contains('"maxWidth":0.01'));
      expect(generated, isNot(contains('radius: "')));
      expect(generated, isNot(contains('strokeWidth = "')));
      expect(generated, isNot(contains('fontSize = "')));
      expect(
        () => PropertyTypeAdapterRegistry.parse(
          'EdgeInsets',
          jsonEncode({'top': -1}),
        ),
        throwsFormatException,
      );
    },
  );
}
