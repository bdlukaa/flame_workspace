import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flutter/material.dart';

import 'component_view.dart';
import 'preview_view.dart';
import 'scene/scene_view.dart';
import 'script_editor.dart';
import 'structure_view.dart';

class DesignView extends StatelessWidget {
  final bool isEditingScript;

  const DesignView({super.key, required this.isEditingScript});

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);

    if (isEditingScript) {
      return Row(children: [
        const Expanded(child: GamePreviewView()),
        Expanded(
          child: ScriptEditor(
            key: scriptEditorKey,
            scriptPath: workbench.state.currentScene.script!.filePath,
          ),
        ),
      ]);
    }

    return const Row(children: [
      Expanded(
        flex: 1,
        child: Column(children: [
          Expanded(flex: 3, child: SceneView()),
          Divider(),
          Expanded(flex: 2, child: ProjectStructureView()),
        ]),
      ),
      Expanded(flex: 3, child: GamePreviewView()),
      Expanded(flex: 1, child: ComponentView()),
    ]);
  }
}
