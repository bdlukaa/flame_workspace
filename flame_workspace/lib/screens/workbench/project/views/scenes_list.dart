import 'package:flame_workspace/screens/workbench/workbench_view.dart';

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
        final (scene, _, _) = sceneResult;

        return ExpansionTile(
          dense: true,
          title: Text(scene.sceneName),
          subtitle: Text(
            '${Uri.file(scene.filePath).toFilePath().split(workbench.project.name).last}'
            '${scene.script?.filePath != null ? '\n${Uri.file(scene.script!.filePath).toFilePath().split(workbench.project.name).last}' : ''}',
          ),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsetsDirectional.all(8),
                  child: ToggleButtons(
                    isSelected: const [false, false, false, true],
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth / 5,
                      minHeight: 40,
                    ),
                    children: [
                      buildOption(Icons.edit, 'Edit'),
                      buildOption(Icons.delete, 'Delete'),
                      buildOption(Icons.content_copy, 'Duplicate'),
                      buildOption(Icons.play_arrow, 'Run'),
                    ],
                    onPressed: (index) async {
                      final semanticScene = workbench
                          .state
                          .workspaceProject
                          .scenes
                          .where(
                            (candidate) => candidate.name == scene.sceneName,
                          )
                          .firstOrNull;
                      if (semanticScene == null) return;
                      switch (index) {
                        case 0:
                          workbench.onEditScene(semanticScene.id);
                          break;
                        case 1:
                          if (workbench.state.workspaceProject.scenes.length <=
                              1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Can not delete the only scene.'),
                              ),
                            );
                            return;
                          }
                          if (!semanticScene.workspaceOwnedSource) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This scene uses developer-owned source files and cannot be deleted from Workspace.',
                                ),
                              ),
                            );
                            return;
                          }
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete ${semanticScene.name}?'),
                              content: const Text(
                                'Workspace scene data, generated adapters, and its Workspace-created '
                                'Dart scaffolding will be removed. This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          final deleted = await workbench.state
                              .deleteWorkspaceScene(
                                semanticScene.id,
                                deleteOwnedSource: true,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  deleted
                                      ? 'Scene ${semanticScene.name} deleted.'
                                      : workbench.state.operationError ??
                                            'Could not delete scene.',
                                ),
                              ),
                            );
                          }
                          break;
                        case 2:
                          final duplicated = await workbench.state
                              .duplicateWorkspaceScene(semanticScene.id);
                          if (!duplicated && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  workbench.state.operationError ??
                                      'Could not duplicate scene.',
                                ),
                              ),
                            );
                          }
                          break;
                        case 3:
                          final ran = await workbench.state.runWorkspaceScene(
                            semanticScene.id,
                          );
                          if (!ran && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  workbench.state.operationError ??
                                      'Could not run scene.',
                                ),
                              ),
                            );
                          }
                          break;
                      }
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildOption(IconData icon, String text) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(text.toUpperCase(), style: theme.textTheme.labelMedium),
            ],
          ),
        );
      },
    );
  }
}
