import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

const generatedFilesDirectory = '.generated';

bool isWorkspaceGeneratedDartFile(
  String filePath, {
  required String projectPath,
  path.Context? context,
}) {
  final paths = context ?? path.context;
  if (paths.extension(filePath) != '.dart') return false;

  final relativePath = paths.relative(
    paths.normalize(filePath),
    from: paths.normalize(projectPath),
  );
  if (paths.isAbsolute(relativePath)) return false;

  final segments = paths.split(relativePath);
  if (segments.first == '..') return false;
  for (var index = 0; index < segments.length - 2; index++) {
    if (segments[index] == 'lib' &&
        segments[index + 1] == generatedFilesDirectory) {
      return true;
    }
  }
  return false;
}

/// A class that modifies files.
///
/// This is used by the IDE to make direct edits to the files.
///
/// The `add-` functions are used to add new code to a Dart string.
///
/// The `write-` functions are used to write the new code to a Dart file.
///
/// See the documentation for each method for more information.
class Writer {
  /// Formats a dart string.
  static String formatDartString(String content) {
    final fomratter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    return fomratter.format(content);
  }

  /// Formats [content] and writes it to [file].
  static Future<void> writeFormatted(File file, String content) =>
      writeBatch({file: formatDartString(content)});

  /// Stages the entire Workspace-owned batch before replacing any destination.
  static Future<void> writeBatch(Map<File, String> contents) async {
    final staged = <File, File>{};
    final originals = <File, String?>{};
    final backups = <File, File>{};
    final published = <File>[];
    try {
      for (final entry in contents.entries) {
        final file = entry.key;
        final old = await file.exists() ? await file.readAsString() : null;
        if (old == entry.value) continue;
        originals[file] = old;
        await file.parent.create(recursive: true);
        final temporary = File(
          '${file.path}.${DateTime.now().microsecondsSinceEpoch}.${staged.length}.tmp',
        );
        staged[file] = temporary;
        await temporary.writeAsString(entry.value, flush: true);
      }
      for (final entry in staged.entries) {
        if (Platform.isWindows && originals[entry.key] != null) {
          final backup = File(
            '${entry.key.path}.${DateTime.now().microsecondsSinceEpoch}.backup',
          );
          await entry.key.rename(backup.path);
          backups[entry.key] = backup;
        }
        await entry.value.rename(entry.key.path);
        published.add(entry.key);
      }
    } catch (_) {
      for (final file in published.reversed) {
        final old = originals[file];
        if (await file.exists()) await file.delete();
        if (backups[file] case final backup?) {
          await backup.rename(file.path);
        } else if (old != null) {
          final rollback = File(
            '${file.path}.${DateTime.now().microsecondsSinceEpoch}.rollback',
          );
          await rollback.writeAsString(old, flush: true);
          await rollback.rename(file.path);
        }
      }
      for (final entry in backups.entries) {
        if (await entry.value.exists()) {
          await entry.value.rename(entry.key.path);
        }
      }
      rethrow;
    } finally {
      for (final temporary in staged.values) {
        if (await temporary.exists()) await temporary.delete();
      }
      for (final backup in backups.values) {
        if (await backup.exists()) await backup.delete();
      }
    }
  }

  static String addImport(String text, String importPath) {
    final import = "import '$importPath';";

    // If there is already
    if (text.contains(import)) return text;

    final firstImport = text.indexOf('import');
    final beforeOffset = text.substring(0, firstImport);
    final afterOffset = text.substring(firstImport);
    return '$beforeOffset$import\n$afterOffset';
  }
}
