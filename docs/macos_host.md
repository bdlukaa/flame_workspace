# macOS editor host and Game Preview

The editor has a standard Flutter macOS host under `flame_workspace/macos/`.
Embedded Game Preview uses `CefPreviewSurface`, the same platform-neutral
`PreviewSurface` implementation used by the Windows editor host. It loads the
URL served by the user's real application via `flutter run -d web-server` into
CEF's off-screen texture; it is not a native child-window embedding.

## Requirements

- macOS 12.0 or newer (required by `webview_cef` 0.6.2 / CEF 149).
- Flutter 3.47+ and CocoaPods.
- Xcode command-line tools and a C++20-capable Apple Clang toolchain.
- `cmake` on `PATH`; `ninja` is recommended. Install with `brew install cmake ninja`.
- Network access on first dependency setup: CocoaPods' `webview_cef` prepare step
downloads CEF and builds `libcef_dll_wrapper`. The first setup/build can take
several minutes and needs several GB of free disk space.

The macOS deployment target is 12.0 and Runner uses C++20. The Podfile's
`post_install` installs the plugin's CEF helper-app embedding build phase. This
is required for the supported multi-process CEF configuration; omitting it
falls back to unsupported single-process mode. Debug and release entitlements
retain the network client/server permissions used by the local preview host. CEF
remains enabled in release builds because the editor's embedded
preview is a product feature. The host intentionally disables App Sandbox so it
can launch Flutter from an external SDK and operate on developer project files.
This is a developer-tool security tradeoff: user code is run only through
explicit actions such as Preview or Test; opening/indexing remains static.
See [`platform_requirements.md`](platform_requirements.md) for the security
implications and requirements for any future sandboxed distribution.

From `flame_workspace/`:

```sh
flutter pub get
cd macos && pod install && cd ..
flutter run -d macos
```

Flutter normally runs CocoaPods automatically, but running `pod install`
explicitly makes the CEF helper integration and initial CEF download visible.
To build:

```sh
flutter build macos
```

By default CEF prepares the host architecture (`arm64` on Apple Silicon,
`x86_64` on Intel). To prepare a universal binary, set
`WEBVIEW_CEF_MACOS_ARCH=universal` when running `pod install`; this downloads
and compiles both architecture slices and needs substantially more disk space.

## Runtime behavior and ownership

- `PreviewSurface` owns loading, reload, widget rendering, and per-preview
  controller disposal. Its texture follows Flutter's layout constraints and
  receives pointer/keyboard focus through the CEF plugin.
- `PreviewProjectRunner` owns the Flutter web-server process. Stopping Preview
  stops that process and disposes the surface controller. The CEF manager is
  shut down when the editor exits, so CEF helper processes are not left behind.
- Runtime inspection and mutation are not provided by embedded web Preview;
  see [`decisions/embedded-preview-runtime-debugging.md`](decisions/embedded-preview-runtime-debugging.md).


The editor code does not call macOS APIs directly. macOS-specific CEF setup is
limited to the package's documented CocoaPods/Xcode configuration and the
platform runner implementation.

## Manual validation checklist

Automated package analysis/tests cannot establish OS-level focus, rendering, or
helper process behavior. On macOS, verify:

1. Build and launch the editor with `flutter run -d macos` on macOS 12+.
2. Open a valid Flame project, start **Preview**, and confirm the live game
   appears inside the Preview panel rather than a separate browser window.
3. Resize the editor and Preview panel repeatedly; verify the game surface
   tracks the available bounds without stale-size areas or clipping.
4. Click/drag inside the game and verify pointer input reaches it. Click a game
   text field and verify keyboard input and focus work; test an IME if available.
5. Trigger **Reload preview** and confirm the embedded page reloads.
6. Stop Preview, start it again, then close the editor while Preview is active.
   Confirm the web-server process and CEF helper processes exit.
7. Repeat on Apple Silicon and Intel if both architectures are supported by the
   release being validated; test universal builds separately if enabled.
