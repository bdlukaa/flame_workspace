# Developer Preview migration baseline

**Baseline date:** 2026-09-28
**Baseline toolchain:** Flutter 3.47.5, Dart 3.13.4, DevTools 2.60.0

This document records the repository state before the Developer Preview modernization. It is a baseline, not a migration implementation. No production code or dependency constraints were changed for this task.

## Package structure

The repository currently contains four Dart/Flutter packages:

| Package | Role observed in the repository |
| --- | --- |
| `flame_workspace/` | Flutter desktop editor UI, project indexing/parsing, source generation, and project runner. |
| `flame_workspace_core/` | Runtime-side Flame component/scene helpers and the legacy Shelf/WebSocket communication server. |
| `flame_workspace_communication_bridge/` | VM Service connection helpers used by workspace/game code. |
| `template/` | Checked-in generated/template Flame project, including `.generated/` output and sample components/scenes. |

Supporting material is in `spec/`, with repository-level tooling in `pub_resolver.dart` and `out.json`.

## SDK and dependency situation

The versions below distinguish manifest constraints from the versions resolved by the current lockfiles after `flutter pub get`.

| Package | SDK constraints | Flame | Analyzer | `vm_service` | `window_manager` |
| --- | --- | --- | --- | --- | --- |
| `flame_workspace` | Dart `>=3.2.0-41.0.dev <4.0.0`; no explicit Flutter constraint | `^1.13.0` -> `1.21.0` | `6.2.0` | not direct; transitive `14.3.1` | `^0.3.7` -> `0.3.9` |
| `flame_workspace_core` | Dart `>=3.2.0-41.0.dev <4.0.0`; Flutter `>=1.17.0` | `^1.13.0` -> `1.38.2` in its lockfile | transitive `6.2.0` | not direct | transitive `0.3.9` |
| `flame_workspace_communication_bridge` | Dart `^3.5.3`; Flutter `>=1.17.0` | none | none | `^14.3.1` -> `14.3.1` | none |
| `template` | Dart `>=3.2.0-41.0.dev <4.0.0`; no explicit Flutter constraint | `^1.21.0` -> `1.21.0` | transitive `6.2.0` | transitive `14.3.1` | `0.3.7` |

The repository was tested with Dart 3.13.4, although the package lockfiles report the minimum SDK ranges selected by their dependency graphs. The manifests use materially different Flame resolutions: the editor and template resolve Flame 1.21.0, while the core lockfile resolves Flame 1.38.2 because its package graph is resolved independently.

Flame extension packages currently present:

- `flame_audio: 2.1.1` in `flame_workspace_core` and `template`.
- `flame_forge2d: 0.15.0+1` in `flame_workspace_core` and `template`.
- `flame_isolate: 0.5.0+1` in `flame_workspace_core` and `template`.

Other notable editor dependencies include `flutter_native_view`, `win32`, `ffi`, `process_run`, `web_socket_channel`, `shelf`, and `shelf_web_socket`. The base template includes the three Flame extension packages and `window_manager` even though the repository rules call for optional Flame packages to be opt-in.

### Local package dependencies

The manifests declare this graph:

```text
flame_workspace
├── flame_workspace_core (path: ../flame_workspace_core)
└── flame_workspace_communication_bridge (path: ../flame_workspace_communication_bridge)

flame_workspace_core
└── flame_workspace (path: ../flame_workspace)
```

`dart pub deps --style=compact` confirms the cycle:

```text
flame_workspace_core -> flame_workspace -> flame_workspace_core
```

This is a package dependency cycle and violates the intended editor -> protocol/runtime direction. The communication bridge does not depend on either workspace package.

## Baseline commands and failures

`flutter pub get` was run in all four package directories. Dependency resolution completed in each package. The editor and template emitted repeated existing plugin metadata warnings for `file_picker` on Linux, macOS, and Windows: the platform packages are referenced as default implementations but do not provide inline implementations. No dependency-resolution failure occurred.

`flutter analyze` and `flutter test` were run in each package. There are no `test/` directories in the repository.

### `flame_workspace`

`flutter analyze` failed with 2 errors, 1 warning, and 4 infos:

- `lib/main.dart:33`: `CardTheme` is not assignable to the current `ThemeData.cardTheme` type `CardThemeData?`.
- `lib/main.dart:57`: `DialogTheme` is not assignable to the current `ThemeData.dialogTheme` type `DialogThemeData?`.
- `lib/screens/workbench/configuration/tabs/workspace_configuration.dart:4`: unused optional `key` parameter.
- `lib/screens/workbench/design/component_view.dart:561`: deprecated `indicatorColor` usage.
- `lib/screens/workbench/design/component_view.dart:565`: deprecated `withOpacity` usage.
- `lib/workbench/generators/properties_generator.dart:55`: missing braces around an `if` statement.
- `lib/workbench/runner/state.dart:31`: missing braces around an `if` statement.

`flutter test` failed because the `test` directory does not exist.

### `flame_workspace_core`

`flutter analyze` failed with 1 error, 1 warning, and 1 info:

- `lib/exports.dart:17`: ambiguous `Matrix4` export from `vector_math.dart` and `vector_math_64.dart`.
- `lib/game/flame_component.dart:46`: overridden parameter is named `t` instead of `dt`.
- `lib/game/flame_component.dart:99`: deprecated `HasGameRef`; current Flame recommends `HasGameReference`.

`flutter test` failed because the `test` directory does not exist.

### `flame_workspace_communication_bridge`

`flutter analyze` passed with no issues.

`flutter test` failed because the `test` directory does not exist. This package currently has no automated tests.

### `template`

`flutter analyze` completed with one warning:

- `pubspec.yaml:36`: declared asset directory `assets/` does not exist in the checked-in template.

`flutter test` failed because the `test` directory does not exist.

## Known deprecated or incompatible Flame APIs

Verified source usages include:

- `HasGameRef` in `flame_workspace_core/lib/game/flame_component.dart`, `flame_workspace/lib/workbench/generators/scene_generator.dart`, and `template/lib/scenes/level_one/level_one_script.dart`. The current Flame analyzer diagnostic explicitly identifies `HasGameRef` as deprecated; new code should use `HasGameReference<T>`.
- Generated scene scripts use `Future<void> update(dt) async`. Flame update callbacks are synchronous (`void update(double dt)`); the generated signature is incompatible with the current lifecycle contract.
- Generated component code uses `Future<void> render(Canvas canvas) async`. Flame rendering is synchronous (`void render(Canvas canvas)`); the generated signature is incompatible with the current lifecycle contract.
- The checked-in template contains the same async `update` and async `render` patterns in `template/lib/`.
- `flame_workspace_core/lib/game/scene.dart` declares `FlameScene.onLoad()` as synchronous while the modern Flame lifecycle is generally asynchronous (`Future<void> onLoad() async`); this requires deliberate compatibility work rather than an automatic replacement.

The editor also contains a large checked-in `built_in_components.dart`/`built_in_mixins.dart` catalog. These are static snapshots and can drift from the Flame version actually installed in a user project.

## Known generated-code and template problems

The generator/template path has the following verified issues:

- `ComponentGenerator` emits async `render` and `SceneGenerator` emits async `update`.
- Scene script generation emits deprecated, untyped `HasGameRef` rather than a typed modern reference mixin.
- `project_template.dart` contains another async `update` example and a malformed-looking generated scene-script interpolation (`\$Scene...}`); this path needs a compile-level fixture check before it is trusted.
- `template/lib/game.dart` contains `Future<void> update(double dt) async` and does not add the created camera to the game, unlike the generator's current `game.dart` text which calls `addAll([camera])`.
- `template/lib/components/colored_circle.dart` and `my_square_component.dart` use async `render` methods.
- `template/pubspec.yaml` declares an absent `assets/` directory.
- Generated output lives under `template/lib/.generated/`, while the editor's runner state comments and paths refer to `lib/generated`; the generated-file convention is not consistent.
- Generated projects currently include `flame_audio`, `flame_forge2d`, `flame_isolate`, and `window_manager` by default.

These findings are source inspection findings; no generated-project migration was attempted in this baseline task.

## Preview and runtime architecture currently in use

The current implementation is a Windows/native-window preview experiment:

1. `FlameProjectRunner` starts `Process.start('flutter', ['run', '-d', 'windows'], ...)`.
2. `RunnerView` calls Win32 `FindWindow` and embeds the game through `flutter_native_view`.
3. The runner communicates with the game over an `IOWebSocketChannel`; the runtime side exposes a Shelf/WebSocket server in `flame_workspace_core/lib/communication/debug_server.dart`.
4. Separately, `flame_workspace_communication_bridge` connects to the Dart VM Service and calls a dynamically named extension such as `ext.fwcm.set_scene_<sceneName>`.
5. The editor therefore currently has two runtime communication paths: legacy custom WebSocket messaging and VM Service helpers.

This differs from the intended Developer Preview direction of an embedded web surface running `flutter run -d web-server`, a platform-neutral preview abstraction, encapsulated process management, and stable VM Service extensions with structured parameters. The current runner also does not discover targets and hard-codes Windows.

## Proposed migration phases

These are sequencing proposals based on the baseline, not completed work:

1. **Make the baseline reproducible.** Decide the supported Dart/Flutter/Flame compatibility range, remove the package cycle, and make each package independently resolvable and analyzable. Preserve the baseline failure list as regression coverage.
2. **Establish package boundaries.** Extract lightweight protocol contracts from the editor/runtime communication code. Make runtime code depend only on protocol and Flame; make the editor depend on protocol/runtime integration without a reverse package dependency.
3. **Modernize runtime lifecycle and generated output.** Replace deprecated Flame APIs, correct synchronous lifecycle signatures, reconcile `World`/camera ownership, and make generated output compile, format, and remain deterministic. Replace static Flame API catalogs with installed-project analysis over time.
4. **Separate semantic model from source rewriting.** Introduce or stabilize the Workspace scene/component model and make editing operate on it. Treat developer-owned Dart files as input; generate clearly marked files in one consistent location.
5. **Replace preview architecture.** Encapsulate Flutter process start/stop/reload/restart and target discovery. Introduce a platform-neutral `PreviewSurface`, initially using web-server preview, and retire native-window/WebSocket coupling after equivalent runtime operations are covered.
6. **Add meaningful regression coverage.** Add focused unit tests for models, protocol, analysis, generators, and paths; then add a fixture-based Developer Preview workflow that resolves, generates, analyzes, tests, launches, connects, performs one runtime operation, hot reloads, and cleans up child processes.

## Scope and remaining limitations

This baseline intentionally did not fix the listed analyzer errors, deprecated APIs, package cycle, generated output, preview runner, or missing tests. Dependency-resolution commands did refresh some local generated metadata during the investigation; unrelated command-generated changes were restored, and pre-existing working-tree changes were preserved.

## Dependency modernization update

The repository now targets the installed stable toolchain: Dart `>=3.13.0 <4.0.0` and Flutter `>=3.47.0` in all four package manifests.

Selected direct dependency constraints:

| Package area | Selected constraint | Resolved version observed |
| --- | --- | --- |
| Flame | `^1.38.2` | `1.38.2` |
| Analyzer | `^10.2.0` | `10.2.0` |
| `dart_style` | `^3.1.7` | `3.1.7` |
| VM Service bridge | `^15.3.0` | `15.3.0` |
| `window_manager` | `^0.5.2` | `0.5.2` |
| `path` | `^1.9.1` | `1.9.1` |
| `yaml` | `^3.1.4` | `3.1.4` |
| `file_picker` | `^8.0.7` | `8.0.7` |
| Flutter linting | `^6.0.0` | `6.0.0` |

Analyzer 10.2.0 is selected because it supports the resolved Flame 1.38.2 source while retaining the AST APIs used by the existing parser. `dartdoc_json` 0.6.0 was removed because it constrains Analyzer to the incompatible 7.x line; the parser now serializes the small AST subset it owns directly. `dart_style` 3.1.7 follows Analyzer 10 and requires passing an explicit `languageVersion` to `DartFormatter`; the writer supplies `DartFormatter.latestLanguageVersion`.

The editor's unused `code_builder` and `source_gen` constraints were removed. `flame_workspace_core` and the checked-in template no longer declare unused `flame_audio`, `flame_forge2d`, or `flame_isolate` dependencies. The generated project defaults retain only Flame, `flame_workspace_runtime`, and `window_manager`; `window_manager` remains because the current generated game imports and uses it. The editor-specific value parser has since moved into `flame_workspace`, so the former core-to-editor path dependency is no longer required.

Direct compatibility updates included the Flutter 3.47 theme data types, the ambiguous `Matrix4` export, current synchronous generated `update`/`render` signatures, and replacement of runtime/template `HasGameRef` usage with `HasGameReference<FlameGame>`. `flutter pub get` succeeds in all four packages without dependency overrides.

## Package-boundary migration update

The package cycle has been removed without changing the preview transport or scene model:

```text
flame_workspace ───────┐
                       ▼
             flame_workspace_protocol
                       ▲
                       │
             flame_workspace_runtime ◄── user game
```

- `flame_workspace_protocol` contains the lightweight message and game-state DTOs and has no Flutter, Flame, or editor dependency.
- `flame_workspace_runtime` contains the Flame integration, `World`-based scene support, selection component, runtime utilities, and the existing WebSocket server. It depends on protocol and Flame, never on the editor.
- `flame_workspace` now depends on protocol/runtime directly. Editor-specific `ValuesParser.parseValue` lives in the editor package instead of the runtime package.
- `flame_workspace_core` remains as a compatibility facade that depends only on protocol/runtime; it no longer points back to `flame_workspace`. New templates use `flame_workspace_runtime` directly.

The generated template keeps the existing minimal runtime dependency set (`flame`, `flame_workspace_runtime`, and `window_manager`). No dependency override or runtime/editor cycle is present. The legacy WebSocket/native-window preview implementation remains intentionally unchanged for a later preview migration.

## Initial semantic scene model

`flame_workspace/lib/workbench/model/semantic_model.dart` now contains the first widget-independent semantic model. `WorkspaceProject` owns `SceneDefinition` objects, which own `ComponentInstance` hierarchies. Instances reference a `ComponentType`, stable deterministic IDs, editable properties, and a `WorkspaceTransform` containing position, size, angle, and anchor data plus priority.

`WorkspaceModelMapper` copies the existing Analyzer/indexer results into this model for the current simple fixture path. The model does not retain AST nodes; the existing indexer DTOs remain a compatibility boundary until later editor migration work. Persistence and Scene View editing are intentionally not implemented yet.

## Cross-platform project runner

`flame_workspace/lib/workbench/runner/project_runner.dart` now owns Flutter process execution behind `ProjectProcessLauncher` and `ProjectProcess` abstractions. `FlutterTarget` represents an explicit device discovered from `flutter devices --machine`, while omitting a target lets Flutter select its normal default. The runner owns start/stop, output streams, `r`/`R` commands, exit state, and cleanup.

`preview.dart` adds a separate web-server preview path using `flutter run -d web-server`, robust URL extraction, preview lifecycle state, and the platform-neutral `PreviewSurface` contract. The current fallback surface records the URL and the Workspace UI displays it; no embedded browser dependency is currently configured, and the legacy native view remains limited to native Run rather than being extended for web preview.
