import 'package:flame_workspace/project/project.dart';
import 'package:flame_workspace/workbench/workbench_view.dart';
import 'package:flutter/material.dart';

import 'welcome/welcome.dart';

void main() {
  runApp(const FlameWorkspaceApp());
}

class FlameWorkspaceApp extends StatelessWidget {
  const FlameWorkspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flame Workspace',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFffb431),
          // surface: Colors.blueGrey,
        ),
        visualDensity: VisualDensity.compact,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomeView(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/project') {
          return MaterialPageRoute(
            builder: (_) => WorkbenchView(
              project: settings.arguments as FlameProject,
            ),
          );
        }
        return null;
      },
    );
  }
}