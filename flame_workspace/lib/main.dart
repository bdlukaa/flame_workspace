import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_view/flutter_native_view.dart';

import 'screens/welcome/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNativeView.ensureInitialized();
  FlameWorkspaceCore.isGame = false;

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
        cardTheme: const CardTheme(
          shape: RoundedRectangleBorder(),
          margin: EdgeInsets.zero,
        ),
        outlinedButtonTheme: const OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
          ),
        ),
        filledButtonTheme: const FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
          ),
        ),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
          ),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
          ),
        ),
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
