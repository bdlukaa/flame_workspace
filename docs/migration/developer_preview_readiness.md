# Developer Preview readiness

**Review date:** 2026-09-29
**Toolchain:** Flutter 3.47.5, Dart 3.13.4

This report describes the current implementation, not the earlier migration
baseline. Capabilities below are limited to workflows present in the editor and
covered by tests; a model/API alone is not considered user-facing support.

## Status

Developer Preview supports editing authored scene composition in Build mode and
running the user's actual Flutter + Flame application in Game mode through the
embedded Flutter Web Preview. Runtime editing is conditional on a real VM Service
connection. Native game execution and native game-window embedding are not
supported.

## Verified workflow

- Create a minimal Flutter + Flame project or open a configured Workspace
  project.
- Explicitly migrate a compatible existing Flame project when typed scene fields
  provide a safe scene-composition mapping. Dynamic or ambiguous composition is
  diagnosed; Workspace does not silently persist an empty scene as a substitute.
- Edit semantic component hierarchy, transforms, supported properties, priority,
  scene background, editor visibility/lock metadata, and declared image
  references in Build mode.
- Use selection, multi-selection/marquee, group movement, transform gizmos,
  grid/snapping, viewport framing, and asset drag/drop in Scene View.
- Undo/redo Build edits, persist scene documents under
  `.flame_workspace/scenes/`, and regenerate additive adapters under
  `lib/.generated/`.
- Start the actual user app in embedded web Preview; use Flutter logs, stop,
  hot reload/restart, and embedded-surface reload.
- When VM Service is connected, inspect the live runtime tree, reconcile it with
  Build State, and mutate supported runtime properties/transforms.

### Build State and Game State

Build mode uses the semantic Workspace model as the authored source of truth.
Saving writes its scene documents and deterministic generated adapters; editor
visibility and lock metadata affect the editor, not game rendering. Developer
behavior remains in developer-owned Dart source.

Game mode represents the live Flame instance. Successful Inspector mutations are
stored as editor-side runtime overrides for display, but do not enter Build State
or its undo history and are not persisted or generated. Stop returns to Build
mode and clears the overrides; a subsequent Play starts from authored values.

The hierarchy's **Local** view is the authored scene. **Runtime** is the actual
component tree obtained from the running game. Runtime-only/dynamically spawned
components can be selected for inspection when their metadata is available, but
are never serialized into Build State automatically.

### Structural synchronization

Component add/remove, reparenting, ordering, and other scene-composition changes
are Build-State operations. Workspace persists/generates the authored scene,
then reloads changed code and explicitly reconstructs the selected Flame `World`
through the registered scene dispatcher. It does not rely on Flutter hot reload
to rerun `onLoad`. Selection is restored when the semantic component still
exists, and the runtime tree is reconciled after reconstruction. Runtime-safe
property/transform edits use VM Service mutation; developer behavior-source
changes use Flutter hot reload/restart.

## Preview and VM Service

Preview starts the real project with `flutter run -d web-server` and displays its
served URL through the platform-neutral `PreviewSurface` abstraction. Preview
supports visual/input iteration, logs, stop, hot reload, hot restart, and reload
of the embedded display. The availability of an embedded surface does not imply
VM Service availability.

Runtime tree inspection, property/transform/background mutation, scene
switching, and pause/resume require a working VM Service connection. These
controls are disabled or reported unavailable without that connection. Runtime
commands use only the stable `ext.flameWorkspace.*` VM Service protocol; there
is no Shelf/WebSocket fallback. Single-frame Step is intentionally absent because
Flame's public game-loop controls do not provide deterministic one-frame
advancement while paused.

## Import and project safety

A project with Workspace configuration and scene documents is loaded as a
Workspace project. For an existing Flutter + Flame project without Workspace
configuration, migration is an explicit operation offered only when the Analyzer
mapping is reliable (for example, supported typed scene fields). Composition
constructed dynamically in arbitrary game code is not inferred. Workspace
reports an actionable ambiguity diagnostic and avoids destructive persistence;
opening/indexing remains static and does not execute project code.

Migration and scene editing preserve developer-owned Dart sources. Workspace
persists authored composition separately and writes clearly separated generated
adapters. Scene scaffolding creates new files only as an explicit operation.

## Host support and limitations

- Embedded CEF Preview is implemented for Windows and macOS. macOS toolchain and
  manual validation requirements are in [`../macos_host.md`](../macos_host.md).
  Linux editor/preview integration still requires validation.
- Native game execution and native child-window embedding are intentionally
  unsupported; Flutter desktop hosts run the editor, not the game.
- VM Service attachment from embedded web-server Preview is not guaranteed and
  may require browser tooling that Workspace cannot assume is installed.
- Scene View does not run arbitrary user `update()` logic. Unsupported component
  renderers use a visible placeholder; built-in editor render adapters cover
  selected common component types only.
- Animation, tilemap, physics, particles, shaders, visual scripting, plugin
  marketplaces, arbitrary custom inspectors, a complete asset-import pipeline,
  and a full source-code IDE are not implemented.
- The `flame_workspace_core` package remains as a compatibility facade for
  existing imports; newly generated projects use `flame_workspace_runtime`.

## Validation

On 2026-09-29, the `flame_workspace` package passed `flutter analyze` and its
full `flutter test` suite (128 tests). The `flame_workspace_runtime` package
passed `flutter analyze` and its full suite (12 tests). These checks include
generated-project and visual-editing/runtime scenarios. They do not replace
manual validation of CEF rendering, keyboard/pointer focus, and process cleanup
on each supported desktop host.
