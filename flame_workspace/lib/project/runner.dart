import 'package:flutter/widgets.dart';

import 'project.dart';

/// The runner for a Flame project. This class is responsible for running the
/// project preview.
///
/// Under the hood, this class uses the `flutter run` command to run the project.
/// Flutter will initialize a web server. The game previewer will then connect
/// to this web server to display the game.
///
/// TODO(runner): Flutter Web is not as performant as Flutter Desktop.
///               We should consider running the app in a desktop proccess and
///               display the window in the previewer. This would allow us to
///               make a performant game previewer. Hot reload be possible when
///               running on native platform.
///
///               A Texture would be necessary to display the preview.
class FlameProjectRunner {
  final FlameProject project;

  final String hostname;
  final int port;

  FlameProjectRunner(
    this.project, {
    this.hostname = '0.0.0.0',
    this.port = 3000,
  });

  bool _isRunning = false;

  /// Whether the project is running.
  bool get isRunning => _isRunning;

  /// Runs the project.
  Future<void> run() async {
    _isRunning = true;

    // final result = await Process.run(
    //   'flutter',
    //   [
    //     'run',
    //     ...['--web-renderer', 'canvaskit'],
    //     ...['-d', 'web-server'],
    //     ...['--web-hostname', hostname],
    //     ...['--web-port', '$port'],
    //   ],
    //   runInShell: true,
    //   workingDirectory: project.projectDirectory.path,
    // );

    await Future.delayed(const Duration(seconds: 35));

    _isRunning = false;
  }

  Widget buildPreview() {
    return const Placeholder();
  }
}
