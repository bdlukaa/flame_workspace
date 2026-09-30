# Flame Workspace

Flame Workspace is a visual development environment for ordinary Flutter + Flame
projects. Flame remains the game engine and Dart remains the source of game
behavior. Workspace owns project analysis, authored scene composition, editing,
and preview orchestration.

Workspace's game execution workflow is an embedded Flutter Web Preview launched
with `flutter run -d web-server`. Native game execution and native game-window
embedding are not supported. CEF-backed embedded preview is implemented for
Windows and macOS; Linux preview-host integration still needs validation. See
[`docs/macos_host.md`](docs/macos_host.md) for macOS setup and manual checks.

> This is an independent personal project and is not affiliated with the Flame
> team. For official Flame tooling, see [Flame Studio](https://github.com/flame-engine/flame/issues/2319).

## Developer Preview workflow

The currently implemented workflow is:

1. Create a minimal Flutter + Flame project, open a Workspace project, or
   explicitly migrate an existing Flame project when Workspace can safely map
   its typed scene composition.
2. Inspect and edit the authored scene in **Build** mode.
3. Save authored scene documents and regenerate deterministic scene adapters.
4. Play the selected scene in **Game** mode using the actual Flutter + Flame app.
5. Inspect the runtime tree and make runtime-only property, transform, or
   background edits when a real VM Service connection is available.
6. Stop to return to Build mode; Game-mode overrides are discarded.

### Build and Game state

**Build** is the authored project state. The semantic Workspace model is the
source of truth for scene composition, hierarchy, component properties,
transforms, priority, and scene background. Build edits participate in
undo/redo. Saving persists scenes as JSON under `.flame_workspace/scenes/` and
writes deterministic adapters under `lib/.generated/`; generated adapters do not
replace developer-owned behavior source.

**Game** is the running Flame instance, not a second authored model. Runtime
property, transform, and scene-background edits are sent to the live game and
held as temporary editor overrides for Inspector display. They do not modify Build values, mark
the authored model dirty, or write Workspace persistence. Stop returns to Build
and clears these overrides; playing again starts from authored values.

While playing, the hierarchy offers **Local** (the authored Build hierarchy)
and **Runtime** (the actual component tree returned by the game). Dynamically
spawned objects appear only in Runtime and are not imported into the authored
scene automatically. Runtime-tree reconciliation reports missing, unexpected,
type, ID, and detectable parent mismatches.

### Preview and runtime editing limits

Preview starts the user's real project via `flutter run -d web-server`. It
supports visual/input iteration, logs, stop, Flutter hot reload/restart, and
embedded-surface reload. Runtime inspection, property/transform mutation,
scene switching, background mutation, and pause/resume require an established VM
Service connection.
A running web preview alone does not guarantee that connection; controls that
need it are unavailable when Flutter does not expose one. Workspace does not
substitute a WebSocket or another runtime transport.

Build-State structural changes (such as adding, removing, reparenting, or
reordering components) are saved/generated and synchronized by reloading the
project code and explicitly reconstructing the selected Flame `World`. Hot
reload alone does not rerun `onLoad`, so Workspace replaces the scene and then
reconciles the runtime tree. Runtime-safe property and transform edits use VM
Service mutations when available. Developer behavior-source edits use Flutter
hot reload/restart as appropriate.

## Import and migration

Workspace projects use `flame_configuration.yaml` and persisted semantic scene
documents. Existing Flutter + Flame projects without Workspace configuration
are not treated as already migrated. Workspace can offer an explicit migration
when typed scene fields provide a safe composition mapping. Dynamic or otherwise
ambiguous composition produces diagnostics instead of silently creating an
empty scene or rewriting developer Dart files. Migration does not promise to
understand arbitrary `onLoad` logic.

## Current limitations

- Runtime editing and inspection are conditional on a real VM Service
  connection; web-server preview frequently lacks one in embedded browser
  configurations.
- Linux embedded-preview host integration has not been validated. Native game
  execution/embedding is intentionally unsupported on every host.
- Workspace does not execute arbitrary user `update()` logic in Scene View.
  Built-in rendering adapters cover selected common types; unsupported custom
  types use an explicit placeholder.
- Animation, tilemap, physics, particle, shader, and visual-scripting editors,
  plugin-provided inspectors/renderers, and a full source-code IDE are not
  implemented.
- Asset discovery uses the project's existing `pubspec.yaml` declarations; a
  full asset-import/management pipeline is not implemented.
- Flame's public game-loop controls do not provide deterministic single-frame
  stepping, so Step is intentionally absent.

## Quick start

```bash
cd flame_workspace
flutter pub get
flutter run
```

Open `template/` in Workspace, or create a project with the project creator. The
checked-in template is an ordinary Flutter + Flame project and can also be
analyzed and run with standard Flutter/Dart tooling. See
[`template/README.md`](template/README.md) for its structure and runtime setup.

### Debug UI inspection with Marionette

The Workspace application initializes `marionette_flutter` only in debug mode.
Profile and release builds use the normal Flutter binding and do not enable the
Marionette integration. To launch a desktop debug session:

```bash
cd flame_workspace
flutter run -d macos    # or -d windows / -d linux
```

Flutter prints the running application's VM Service URL in the terminal. Keep
that URL available to the Marionette tooling when connecting to the Workspace
UI; it is the debug application's service endpoint, not the VM Service of a
user-game preview. If a tool asks for a WebSocket URI, use the WebSocket form
reported by Flutter/DevTools for that same VM Service rather than starting a
second transport. Marionette is a development/test aid and is not initialized
in generated user games.

For repository validation:

```bash
flutter analyze
flutter test --concurrency=1
```

The `broken_project` fixture intentionally contains syntax errors; indexing must
report them without crashing Workspace.

## Package layout

- `flame_workspace/` — editor UI, Analyzer-backed discovery, semantic model,
  persistence/generation, Scene View, runners, and editor-side VM Service client
  integration.
- `flame_workspace_protocol/` — lightweight runtime request/response models
  and stable VM Service extension names.
- `flame_workspace_runtime/` — Flame `World` integration and runtime VM Service
  extensions installed into user games. It depends on protocol, never on the
  editor.
- `flame_workspace_communication_bridge/` — editor-side VM Service connection
  and invocation helpers.
- `flame_workspace_core/` — compatibility facade for existing imports; new
  projects should depend on `flame_workspace_runtime`.
- `template/` — checked-in reference Flutter + Flame project.
- `fixtures/` — intentionally small project-analysis and import fixtures.

## Architecture

```text
Analyzer / developer Dart
          ↓
Workspace semantic Build State
          ↓
.flame_workspace persistence
          ↓
deterministic generated adapters
          ↓
running Flame Game State
```

Build State and Game State are distinct. Scene composition is authored in the
semantic model and persisted independently from user behavior code. Game State
is the actual Flame runtime. Runtime edits affect it only through
`ext.flameWorkspace.*` VM Service extensions and never flow back into authored
scene data automatically.

Package dependencies remain acyclic:

```text
flame_workspace ──────→ communication_bridge ──→ protocol
       └──────────────────────────────────────→ protocol
flame_workspace_runtime ──────────────────────→ protocol
user game ────────────────────────────────────→ runtime
flame_workspace_core (compatibility facade) ──→ runtime
```

The obsolete Shelf/WebSocket runtime transport is not part of the architecture.
See [`docs/migration/developer_preview_migration.md`](docs/migration/developer_preview_migration.md)
for the current workflow and migration notes,
[`docs/migration/developer_preview_readiness.md`](docs/migration/developer_preview_readiness.md)
for verified capabilities and limitations, and
[`docs/decisions/embedded-preview-runtime-debugging.md`](docs/decisions/embedded-preview-runtime-debugging.md)
for the runtime-debugging contract.
