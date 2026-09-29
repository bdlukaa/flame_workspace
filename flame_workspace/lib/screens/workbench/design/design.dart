import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/widgets/resizable_split_view.dart';
import 'package:flutter/material.dart';

import 'component_view.dart';
import 'preview_view.dart';
import 'scene/scene_view.dart';
import 'script_editor.dart';
import 'structure_view.dart';

class const DesignView({super.key, required final bool isEditingScript})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);

    if (isEditingScript) {
      return ResizableSplitView(
        id: 'script.previewEditorRatio',
        direction: SplitDirection.horizontal,
        initialRatio: 0.6,
        minFirstSize: 320,
        minSecondSize: 280,
        first: const GamePreviewView(key: ValueKey('script-preview')),
        second: ScriptEditor(
          key: scriptEditorKey,
          scriptPath: workbench.state.currentSceneSource!.script!.filePath,
        ),
      );
    }

    return ResizableSplitView(
      id: 'design.leftWidth',
      direction: SplitDirection.horizontal,
      initialRatio: 0.2,
      minFirstSize: 180,
      minSecondSize: 540,
      first: ResizableSplitView(
        id: 'design.sceneHierarchyRatio',
        direction: SplitDirection.vertical,
        initialRatio: 0.6,
        minFirstSize: 160,
        minSecondSize: 140,
        first: const SceneView(key: ValueKey('design-scene')),
        second: const ProjectStructureView(key: ValueKey('design-hierarchy')),
      ),
      second: ResizableSplitView(
        id: 'design.centerInspectorRatio',
        direction: SplitDirection.horizontal,
        initialRatio: 0.75,
        minFirstSize: 320,
        minSecondSize: 220,
        first: const GamePreviewView(key: ValueKey('design-preview')),
        second: const ComponentView(key: ValueKey('design-inspector')),
      ),
    );
  }
}
