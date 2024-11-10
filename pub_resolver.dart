import 'dart:io';

void main() async {
  final currentDirectory = Directory.current;
  final directories = currentDirectory
      .listSync(recursive: true, followLinks: false)
      .whereType<Directory>()
      .where((dir) => File('${dir.path}/pubspec.yaml').existsSync());

  for (var dir in directories) {
    print('Processing directory: ${dir.path}');
    await runCommand('flutter', ['clean'], dir.path);
    await runCommand('flutter', ['pub', 'get'], dir.path);
    await runCommand('flutter', ['pub', 'upgrade'], dir.path);
  }
}

Future<void> runCommand(
    String command, List<String> arguments, String workingDirectory) async {
  final process = await Process.start(command, arguments,
      workingDirectory: workingDirectory, runInShell: true);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print(
        'Command $command ${arguments.join(' ')} failed with exit code $exitCode');
  }
}
