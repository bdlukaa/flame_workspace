import 'package:flame_workspace/main.dart';
import 'package:flame_workspace/marionette/workspace_tools.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  test('registers schema-bearing diagnostic tools in debug mode', () {
    initializeFlameWorkspaceBinding();
    initializeWorkspaceMarionetteTools();

    final extensions = {
      for (final extension in customExtensionRegistry)
        extension.name: extension,
    };
    expect(
      extensions.keys,
      containsAll([
        'workspace.getState',
        'workspace.getCurrentScene',
        'workspace.getBuildHierarchy',
        'workspace.getRuntimeHierarchy',
        'workspace.getDiagnostics',
        'workspace.getPreviewLogs',
        'workspace.getSyncStatus',
        'workspace.selectScene',
      ]),
    );
    expect(
      extensions.values.every((extension) => extension.inputSchema != null),
      isTrue,
    );
    expect(extensions['workspace.selectScene']!.inputSchema!.required, [
      'sceneId',
    ]);
  });
}
