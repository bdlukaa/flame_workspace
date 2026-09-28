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
  static Future<void> writeFormatted(File file, String content) {
    return file.writeAsString(formatDartString(content));
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
