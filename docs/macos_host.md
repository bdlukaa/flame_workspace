# macOS editor host

The `flame_workspace` Flutter app now has a standard macOS host under
`flame_workspace/macos/`. Its generated bundle identifier follows the existing
Flutter template identity (`com.example.flameWorkspace`), and the application
name remains `flame_workspace`.

## Platform boundary

`lib/workbench/runner/view.dart` is the shared import boundary for the
`RunnerView` mixin. The non-I/O stub does not depend on native preview APIs;
I/O desktop hosts select `view_io.dart`. That implementation keeps the legacy
Win32 `FindWindow` + `flutter_native_view` embedding together and checks
`Platform.isWindows` before creating a native view. On macOS the Game Preview
panel reports that preview is unsupported instead of starting or embedding a
game. The current `webview_cef` macOS pod setup also invokes CMake to prepare
CEF, even though this host does not use the preview surface; CMake must be
available for the current native build until that dependency is isolated or
replaced.

The app entry point initializes native-view support through the runner-view
boundary only on Windows. Starting the editor on macOS does not initialize the
Windows native-view plugin.

## Remaining Windows-only functionality

- `lib/workbench/runner/view_io.dart` contains the Win32 lookup and
  `flutter_native_view` usage. It remains for the existing Windows host and is
  not a cross-platform preview implementation.
- `windows/` contains the Windows runner and generated Windows plugin setup.
- `win32`, `ffi`, and `flutter_native_view` remain declared in
  `pubspec.yaml` because the retained Windows embedding still uses them.
- `window_manager` remains in use for desktop window close handling. It is a
  plugin integration rather than the native game embedding boundary.

The later cross-platform preview work should replace this legacy native
embedding with the platform-neutral `PreviewSurface` and actual game served
through Flutter's web-server target, then remove `flutter_native_view`, Win32
and FFI dependencies if nothing else requires them. This task does not implement
that preview migration.
