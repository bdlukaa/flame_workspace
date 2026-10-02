import 'dart:ui' show AppExitResponse;

import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/project/workspace_navigation.dart';
import 'package:flame_workspace/screens/workbench/workbench_view.dart';
import 'package:flame_workspace/marionette/workspace_tools.dart';

import 'package:flame_workspace/workbench/runner/cef_preview_surface.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'screens/welcome/welcome.dart';

/// Initializes exactly one Flutter binding for the Workspace process.
///
/// Marionette is intentionally a debug-only development aid. Profile and
/// release builds retain the regular Flutter binding and production behavior.
void initializeFlameWorkspaceBinding() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
}

void main() async {
  initializeFlameWorkspaceBinding();
  initializeWorkspaceMarionetteTools(navigatorKey: workspaceNavigatorKey);

  runApp(const FlameWorkspaceApp());
}

class const FlameWorkspaceApp({super.key}) extends StatefulWidget {
  @override
  State<FlameWorkspaceApp> createState() => _FlameWorkspaceAppState();
}

class _FlameWorkspaceAppState extends State<FlameWorkspaceApp> {
  static const _windowChannel = MethodChannel('flameWorkspace/window');
  late final AppLifecycleListener _lifecycleListener;
  Future<AppExitResponse>? _exitInFlight;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _shutdownPreviewSurface,
    );
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      _windowChannel.setMethodCallHandler((call) async {
        if (call.method != 'requestClose') {
          throw MissingPluginException(
            'Unknown window request: ${call.method}',
          );
        }
        return await _shutdownPreviewSurface() == AppExitResponse.exit;
      });
    }
  }

  Future<AppExitResponse> _shutdownPreviewSurface() {
    return _exitInFlight ??= _prepareForExit().whenComplete(() {
      _exitInFlight = null;
    });
  }

  Future<AppExitResponse> _prepareForExit() async {
    try {
      if (!await WorkspaceNavigation.closeCurrentProject()) {
        return AppExitResponse.cancel;
      }
      await shutdownCefPreviewSurface();
      return AppExitResponse.exit;
    } catch (error) {
      debugPrint('Could not close Workspace safely: $error');
      return AppExitResponse.cancel;
    }
  }

  @override
  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      _windowChannel.setMethodCallHandler(null);
    }
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: workspaceNavigatorKey,
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
        cardTheme: const CardThemeData(
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
        dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder()),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(),
        ),
      ),
      initialRoute: '/',
      routes: {'/': (_) => const WelcomeView()},
      onGenerateRoute: (settings) {
        if (settings.name == '/project') {
          return MaterialPageRoute(
            builder: (_) =>
                WorkbenchView(project: settings.arguments as FlameProject),
          );
        }
        return null;
      },
    );
  }
}
