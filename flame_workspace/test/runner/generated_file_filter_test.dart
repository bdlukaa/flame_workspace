import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Workspace-generated Dart path filtering', () {
    test('excludes Dart files under lib/.generated', () {
      expect(
        isWorkspaceGeneratedDartFile(
          path.join('/project', 'lib', generatedFilesDirectory, 'output.dart'),
          projectPath: '/project',
        ),
        isTrue,
      );
    });

    test(
      'does not exclude developer Dart files or scene persistence files',
      () {
        expect(
          isWorkspaceGeneratedDartFile(
            path.join('/project', 'lib', 'game.dart'),
            projectPath: '/project',
          ),
          isFalse,
        );
        expect(
          isWorkspaceGeneratedDartFile(
            path.join('/project', '.flame_workspace', 'scenes', 'scene.dart'),
            projectPath: '/project',
          ),
          isFalse,
        );
      },
    );

    test('does not ignore directories that merely contain generated', () {
      expect(
        isWorkspaceGeneratedDartFile(
          path.join('/project', 'lib', 'generated_code', 'game.dart'),
          projectPath: '/project',
        ),
        isFalse,
      );
    });

    test('matches path segments independent of path separator style', () {
      expect(
        isWorkspaceGeneratedDartFile(
          r'C:\project\lib\.generated\output.dart',
          projectPath: r'C:\project',
          context: path.windows,
        ),
        isTrue,
      );
      expect(
        isWorkspaceGeneratedDartFile(
          r'C:\project\lib\generated_code\output.dart',
          projectPath: r'C:\project',
          context: path.windows,
        ),
        isFalse,
      );
    });
  });
}
