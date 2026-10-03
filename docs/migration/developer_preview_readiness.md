# Developer Preview readiness

**Review date:** 2026-10-03
**Toolchain:** Flutter 3.47.5, Dart 3.13.4

This report describes the current implementation, not the earlier migration
baseline. Capabilities below are limited to workflows present in the editor and
covered by tests; a model/API alone is not considered user-facing support.

## Status

**Authoring-recovery phase: NOT READY.** The six-part-character journey and the no-script movement/target/restart game have not passed the real UI gate. In a UI-created project, the remote runtime pinned by `pubspec.lock` lacks `createWorkspaceComponentJson`, so generated code cannot compile. The embedded CEF Preview does not implement direct Build pointer drag/resize; only the separate Scene View does. No authorable movement, overlap, success, or restart behavior exists. See [`../stabilization/authoring_recovery.md`](../stabilization/authoring_recovery.md) for observed tests and reproduction. The older descriptions below cover *available subsystems*, not acceptance of the current product goal.

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

Component add/remove, reparenting and ordering are Build-State operations.
When the connected runtime advertises live composition, supported components
are changed through the VM Service without recompiling. Unsupported components
or older runtimes retain a reconstruct/reload fallback; persistence does not
itself reconstruct Preview. Selection is restored when the component survives;
runtime reconciliation is available only after a successful attachment.
Runtime-safe property/transform edits use VM Service mutation; developer
behavior-source changes may still require Flutter compilation.

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

## Stability gate

The Developer Preview phase is complete only when this checklist is green for
all supported environments:

- **Project safety:** developer-owned Dart remains byte-identical; unsupported
  or ambiguous projects are diagnosed instead of being silently migrated.
- **Authoring:** supported core components, hierarchy operations, metadata,
  transforms, and supported typed values survive save/reopen.
- **Generation:** unchanged semantic input produces deterministic,
  analyzer-valid generated adapters and a generated project that builds.
- **Preview:** start/stop, hot reload/restart, retry, and cleanup are repeatable
  without stale process or surface state.
- **Runtime:** VM Service availability is reported truthfully; runtime-only
  overrides never persist implicitly; reconciliation diagnostics are actionable.
- **Recovery:** malformed source, unsupported values, failed generation, and
  failed preview operations remain diagnosable and retryable without corrupting
  newer state.
- **Quality:** analysis, the complete serialized test suite, generated-project
  checks, and the Marionette smoke journey pass.
- **UI:** core editor workflows remain usable without modal transient editor
  surfaces, and diagnostics remain visible and actionable.

## Compatibility matrix

The checked-in fixture matrix currently covers these expected behaviors:

| Fixture/scenario | Expected behavior |
| --- | --- |
| Workspace-created or configured modern Workspace project | Opens, indexes, edits, persists, and regenerates Workspace-owned output. |
| Ordinary simple Flame project | Static indexing succeeds; migration is offered only when typed scene mapping is safe. |
| Dynamic/ambiguous Flame composition | Opens for diagnosis; automatic migration and destructive scene persistence are refused. |
| Indirect Flame component inheritance | Analyzer discovery follows the resolved type hierarchy. |
| Multiple World/scene declarations | Scenes are discovered deterministically and selected explicitly. |
| Syntax-broken Dart | Project remains diagnosable; indexing reports diagnostics instead of silently fabricating authored state. |
| Required constructor parameters | Components are addable only when the capability contract can represent every required argument. |
| Nullable, enum, and structured values | Typed adapters preserve nullability, enum identity, and structured semantics. |
| Custom user PositionComponent subclass | Supported only when discovered construction and property capabilities are complete. |
| Missing/undeclared assets | Asset diagnostics remain visible; invalid references are not silently accepted. |
| Project path containing spaces | Path handling uses normalized platform paths and remains importable. |
| Existing generated Workspace files | Workspace-owned generated output is replaceable; developer-owned Dart is not rewritten. |
| Unsupported Flame APIs/components | Discovery does not imply addability; unsupported entries are refused or diagnosed. |

This matrix describes the intended safety contract; each row must remain backed
by fixture or integration assertions before the phase is declared complete.

## Persistence compatibility

Scene documents currently use a backward-compatible, field-based JSON format
without an explicit schema-version field. Older documents remain readable when
known fields are present, and unknown fields are ignored by the semantic model.
This is acceptable for the current preview because the persisted model is still
small and no migration boundary has been introduced. Before adding a new
incompatible authored-data family, introduce an explicit schema version and
reject newer/unknown versions with a structured diagnostic rather than silently
reinterpret them.

## Validation

On 2026-09-30, `flutter analyze` passed for the `flame_workspace` package.
The focused inline preview-toolbar widget test also passes. A serialized full
`flutter test --concurrency=1` run was started, but did not complete within the
available validation window; it reached the generated-project and runtime
scenarios while reporting two failures in the existing suite. The failures were
not suppressed or converted into skipped tests. Package directories for
`flame_workspace_protocol`, `flame_workspace_runtime`, and
`flame_workspace_communication_bridge` do not currently contain test directories. `make check`
likewise started successfully, including fixture pub gets and fixture analysis,
but timed out while running the workspace test suite. These checks do not replace manual validation of CEF rendering,
keyboard/pointer focus, VM Service attachment, and process cleanup on each
supported desktop host.
