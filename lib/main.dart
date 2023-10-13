import 'package:flame_workspace/project/workbench_view.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFffb431)),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomeView(),
        '/project': (_) => const WorkbenchView(),
      },
    );
  }
}
