import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/workbench/generators/scene_generator.dart';
import 'package:flame_workspace/workbench/parser/scene.dart';
import 'package:flutter/material.dart';

class ScenesListView extends StatelessWidget {
  const ScenesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    final scenes = workbench.state.scenes;

    assert(scenes.isNotEmpty, 'The project must have at least one scene.');
    return ListView.builder(
      itemCount: scenes.length,
      itemBuilder: (context, index) {
        final sceneResult = scenes.elementAt(index);
        final scene = sceneResult.$1;

        return ExpansionTile(
          dense: true,
          title: Text(scene.sceneName),
          subtitle: Text(
            '${Uri.file(scene.filePath).toFilePath().split(workbench.project.name).last}'
            '${scene.script?.filePath != null ? '\n${Uri.file(scene.script!.filePath).toFilePath().split(workbench.project.name).last}' : ''}',
          ),
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 8.0,
                  bottom: 8.0,
                  start: 8.0,
                  end: 8.0,
                ),
                child: ToggleButtons(
                  isSelected: const [false, false, false, true],
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth / 5,
                    minHeight: 40.0,
                  ),
                  children: [
                    buildOption(Icons.edit, 'Edit'),
                    buildOption(Icons.delete, 'Delete'),
                    buildOption(Icons.content_copy, 'Duplicate'),
                    buildOption(Icons.play_arrow, 'Run'),
                  ],
                  onPressed: (i) {
                    final helper = SceneHelper.fromWorkbench(scene, workbench);
                    switch (i) {
                      case 0: // Edit
                        break;
                      case 1: // Delete
                        if (scenes.length == 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Can not delete the only scene.'),
                            ),
                          );
                        } else {
                          helper.delete(
                            scenes
                                .firstWhere((s) => s.$1.name != scene.name)
                                .$1,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Scene ${scene.sceneName} deleted.',
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  SceneGenerator.createScene(
                                    workbench.project,
                                    scene.sceneName,
                                    true,
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        break;
                      case 2: // Duplicate
                        break;
                      case 3: // Run
                        break;
                      default:
                    }
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget buildOption(IconData icon, String text) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12.0,
        ),
        child: Row(children: [
          Icon(icon, size: 20.0),
          const SizedBox(width: 8.0),
          Text(text.toUpperCase(), style: theme.textTheme.labelMedium),
        ]),
      );
    });
  }
}
