import 'package:flutter/material.dart';

import 'component_view.dart';
import 'preview_view.dart';
import 'scene/scene_view.dart';
import 'structure_view.dart';

class DesignView extends StatelessWidget {
  const DesignView({super.key});

  @override
  Widget build(BuildContext context) {
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
