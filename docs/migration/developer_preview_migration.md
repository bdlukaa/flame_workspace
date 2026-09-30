# Developer Preview architecture and migration status

**Status reviewed:** 2026-09-29
**Toolchain:** Flutter 3.47.5, Dart 3.13.4

This document describes the current architecture after the Developer Preview
implementation work. Earlier migration-baseline observations and intermediate
proposals are superseded by the current contracts below.

## Authoritative state and data flow

```text
Analyzer / developer Dart
          ↓
Workspace semantic Build State
          ↓
.flame_workspace/scenes/*.json
          ↓
deterministic generated adapters
          ↓
running Flame Game State
```

The Analyzer is an input for understanding developer code; it is not the mutable
scene model. `WorkspaceEditorModel` owns authored composition. Developer-owned
behavior and component source remains ordinary Dart and is not rewritten for
routine scene editing.

Build State and Game State are separate:

- **Build State** owns authored scenes, hierarchy, component identity, supported
  property values, transforms, priority, background, and editor-only visibility
  and lock metadata. Build edits participate in undo/redo and become persistent
  when saved.
- **Game State** is the actual running Flame instance. Successful runtime edits
  can be represented in a transient `RuntimeOverrideStore` so the Inspector
  shows the live value. Overrides are keyed by semantic component ID, are not
  saved/generated/undoable, and are cleared when Stop returns to Build mode.

`ComponentInstance.id`, `FlameKey.name`, and runtime `componentId` are the same
semantic identity. Declaration names are source/display metadata, not runtime
identity.

## Authored persistence and generation

Workspace stores scene documents under `.flame_workspace/scenes/`. Generated
composition adapters and the global scene dispatcher live under
`lib/.generated/`. Generation is deterministic and additive: scene data is
populated into a `FlameScene`/Flame `World`, while game behavior remains in
developer-owned sources. Workspace does not restore old generated component
field hooks or depend on arbitrary reflection to construct components.

Build-State component add/remove, reparenting, sibling ordering, and other
structural changes require scene reconstruction. Workspace writes the updated
semantic scene and adapters, reloads changed project code, then explicitly
switches/recreates the selected scene using the generated dispatcher. Flutter
hot reload alone does not rerun an existing World's `onLoad`; it is not used as
the structural synchronization contract. The resulting runtime tree is
reconciled with Build State and reports actionable missing/unexpected/type/ID
and detectable parent mismatches.

Runtime-safe property and transform edits are sent through VM Service when
available. Source behavior edits continue to use Flutter hot reload/restart.
Undo/redo uses the same synchronization classification as the originating Build
edit; Game State overrides stay outside Build history.

## Build and Game hierarchy

The hierarchy exposes two views while playing:

- **Local** shows the authored Build-State scene hierarchy.
- **Runtime** shows the component tree returned by the running game, including
  game-spawned runtime-only objects.

Runtime-only nodes can be selected for inspection when the runtime metadata
supports it. They are visually distinguished and do not become authored scene
components automatically. Refresh and known runtime mutations update the
runtime snapshot/reconciliation.

## Project import and migration

A configured Workspace project is loaded from its configuration and persisted
scene documents. An ordinary Flutter + Flame project is not silently treated as
a completed Workspace migration.

Workspace offers explicit migration only when semantic analysis can safely map
scene composition, such as supported typed component fields. It does not infer a
scene merely because a component's source file matches the scene source file, and
does not claim to understand arbitrary/dynamic construction in `onLoad` or game
logic. Unsupported or ambiguous composition produces diagnostics and is not
persisted as an empty authored scene. Migration preserves existing developer
Dart source; Workspace documents and generated adapters are created only after a
valid mapping and explicit migration.

The project importer and fixtures cover modern Workspace documents, legacy
Workspace-style typed fields, ordinary Flame projects, nested custom components,
and unsupported dynamic composition. Arbitrary Flame architecture is not
promised to be importable without user restructuring.

## Preview and runtime communication

The only game execution workflow is embedded Flutter Web Preview:

```text
Flame Workspace
       ↓
flutter run -d web-server
       ↓
user's actual Flutter + Flame application
       ↓
PreviewSurface
```

The process runner owns start/stop, logs, exit/failure reporting, Flutter hot
reload/restart, and cleanup. Reloading the embedded display is distinct from
Flutter hot reload/restart. Native game execution and native game-window
embedding are intentionally unsupported.

`flame_workspace_protocol` contains structured request/response contracts;
`flame_workspace_runtime` registers stable `ext.flameWorkspace.*` VM Service
extensions against the real Flame game; the editor-side communication bridge
invokes those extensions. Runtime inspection and mutation are available only
when Flutter provides a live usable VM Service connection. A web-server URL
alone is not sufficient, and Workspace does not add a Shelf/WebSocket fallback.

When connected, runtime extensions cover state and component-tree inspection,
supported property and transform/background mutation, scene switching, and
pause/resume. Unsupported operations and reconciliation failures produce coded
diagnostics with operation context and recovery guidance. Single-frame Step is
not implemented because Flame does not expose a deterministic public mechanism
to advance exactly one update/render frame while paused.

CEF-backed embedded Preview is implemented on Windows and macOS. Linux preview
host integration still requires validation. See
[`../macos_host.md`](../macos_host.md) for macOS build requirements and manual
checks, and [`../decisions/embedded-preview-runtime-debugging.md`](../decisions/embedded-preview-runtime-debugging.md)
for the runtime-debugging decision.

## Scene View and assets

Scene View edits Build State without running arbitrary user `update()` logic.
It supports selection and multi-selection, hierarchy operations, basic
PositionComponent transforms (including scale), grid/snapping and viewport
navigation. It uses editor render adapters for selected common Flame component
types and an explicit placeholder for unsupported custom renderers.

Asset discovery reads declarations already present in `pubspec.yaml`. Declared
image assets can be dragged into Scene View to create supported sprite-like
components or used to replace a selected component's image. Undeclared files are
diagnosed; Workspace does not silently rewrite `pubspec.yaml` or provide a full
asset import pipeline.

## Package boundaries and removed paths

```text
flame_workspace ───────→ communication_bridge ──→ protocol
       └───────────────────────────────────────→ protocol
flame_workspace_runtime ───────────────────────→ protocol
user game ─────────────────────────────────────→ runtime
```

The runtime package does not depend on the editor. The old Shelf/WebSocket
runtime transport, source-rewriting scene/component helpers, runtime selection
wrapper, serialized runtime-tree extension, and generated add/remove mutation
hooks are not part of the current architecture. Structural synchronization uses
scene reconstruction instead.

`flame_workspace_core` remains only as a compatibility facade for projects that
still import its package name. New projects and the checked-in template depend on
`flame_workspace_runtime` directly.

## Current limitations

- Embedded Web Preview can run without VM Service; in that case runtime tree,
  Inspector mutation, pause/resume, and runtime scene controls are unavailable.
- Linux embedded Preview and host-level focus/rendering/process behavior still
  need validation on target systems.
- No native game execution, single-frame stepping, animation/tilemap/physics/
  particle/shader editor, visual scripting, arbitrary custom inspector, full
  asset pipeline, or complete source-code IDE is provided.
- Scene View rendering is not a substitute for executing the game's behavior;
  unsupported component types use a placeholder.
- Dynamic project composition that cannot be safely mapped is diagnosed rather
  than imported automatically.
