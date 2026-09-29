# Flame Workspace

## Host platform requirements

Flame Workspace is a desktop editor for Windows 10+, macOS 12+, and Linux
(x64/arm64), subject to each platform's Flutter and CEF native toolchain
requirements. See [`docs/platform_requirements.md`](docs/platform_requirements.md)
for the host matrix, dependency-specific limits, and macOS subprocess permission
requirements.

Flame Workspace is a visual development environment for normal Flutter + Flame
projects. Flame remains the runtime engine and Dart remains the source of game
behavior; Workspace owns project analysis, scene composition, editing, and
preview orchestration. Flame Workspace currently executes projects only through
an embedded Flutter Web Preview; native game execution and embedding are
intentionally unsupported for now.

> This is an independent personal project and is not affiliated with the Flame
> team. For official Flame tooling, see [Flame Studio](https://github.com/flame-engine/flame/issues/2319).

## Developer Preview status

The repository is in the Developer Preview milestone. The following workflow is
implemented and covered by package and fixture tests:

- create a minimal Flutter + Flame project or open an existing project;
- resolve and semantically index Flame components, worlds, and inheritance;
- edit a widget-independent scene model and component hierarchy;
- persist scene composition under `.flame_workspace/scenes/`;
- generate deterministic additive adapters under `lib/.generated/`;
- inspect and edit basic transforms and supported properties;
- launch the actual game through one execution workflow: embedded Flutter Web
  Preview using `flutter run -d web-server` and the platform-neutral
  `PreviewSurface` abstraction;
- hot reload/restart, inspect logs, and clean up the Preview process;
- use `ext.flameWorkspace.*` only when Flutter actually exposes a VM Service;
  web-server Preview does not promise runtime debugging.

Scene composition has one source of truth: Analyzer-discovered developer code is
read-only to the indexer, Workspace edits are persisted under
`.flame_workspace/scenes/`, and `ScenePersistenceGenerator` writes additive
adapters under `lib/.generated/`. Scene scaffolding creates new source files but
does not inject mixins into existing classes.

### Experimental and platform-limited

- Embedded CEF Preview is implemented for Windows and macOS. The macOS host
  requires the documented CEF/CocoaPods setup in
  [`docs/macos_host.md`](docs/macos_host.md); verify its rendering and input
  behavior with the manual checklist on a macOS machine. Linux host integration
  still requires validation.
- Embedded Web Preview is for visual/input iteration. Flutter's web-server
  debug attachment depends on browser tooling and may require the Dart Debug
  Chrome extension; Workspace does not assume it is available in an embedded
  surface. Runtime inspection and mutation are unavailable unless an actual VM
  Service connection is established.
- Generic runtime component mutation depends on generated scene hooks, and
  generic property mutation depends on a generated property callback.

### Not implemented yet

Multi-selection, snapping, animation/tilemap/physics editors, visual scripting,
a full asset import pipeline, and a complete source-code IDE are outside the
Developer Preview scope.

## Quick start

```bash
cd flame_workspace
flutter pub get
flutter run
```

Open `template/` in the running Workspace, or use the project creator to create
a new project. The checked-in template is a small modern Flame project and is
kept as an ordinary Flutter project that can also be analyzed and tested without
Workspace.

For repository validation:

```bash
flutter analyze
flutter test --concurrency=1
```

The editor currently reports existing Analyzer API deprecation infos. The
intentionally broken fixture also fails analysis by design; Workspace indexing
must remain recoverable in that case.

## Package layout

- `flame_workspace/` — Flutter editor UI, Analyzer-backed discovery, semantic
  model, persistence/generation, Scene View, runners, and editor-side VM Service
  client integration.
- `flame_workspace_protocol/` — lightweight runtime request/response models and
  stable VM Service extension names.
- `flame_workspace_runtime/` — Flame `World`/component integration and runtime
  VM Service extensions installed into user games. It depends on protocol, never
  on the editor.
- `flame_workspace_communication_bridge/` — editor-side VM Service connection
  and invocation helpers; it depends on protocol.
- `flame_workspace_core/` — compatibility facade for projects that still import
  the former package; new projects should depend on
  `flame_workspace_runtime`.
- `template/` — checked-in minimal project example.
- `fixtures/` — intentionally small analyzer and discovery compatibility
  projects, including inheritance, multiple worlds, and a broken project.

## Architecture

```text
Flutter + Flame project
        │
        ▼
Analyzer-backed discovery
        │
        ▼
Workspace semantic scene model
        ├── Scene View / hierarchy / Inspector
        ├── JSON persistence and deterministic adapters
        └── project generation

Embedded Web Preview                  Run target
(actual game, visual/input)           (native or compatible target)
          │                                        │
          ▼                                        ▼
Flutter process runner                    Flutter process runner
          │                                        │
          ▼                                        ▼
PreviewSurface                         Dart VM Service
                                                   │
                                                   ▼
                                  flame_workspace_runtime → Flame World
```

Package dependencies are acyclic and point toward shared contracts:

```text
flame_workspace ──────→ flame_workspace_communication_bridge ──→ protocol
       └──────────────────────────────────────────────────────→ protocol
flame_workspace_runtime ──────────────────────────────────────→ protocol
flame_workspace_core (compatibility facade) ──────────────────→ runtime
user game ────────────────────────────────────────────────────→ runtime
```

The editor has no direct runtime-package dependency. Editor-side VM Service
communication goes through the bridge and protocol; user game projects depend on
`flame_workspace_runtime` for Flame integration. The protocol contains only
runtime-neutral messages and extension names. Workspace generation may emit
runtime imports into a user's game source, but that does not create an editor
package dependency.

Workspace communicates with a running game through stable structured extensions
such as `ext.flameWorkspace.getState`, `getComponentTree`, `setProperty`, and
`setTransform`. The obsolete Shelf/WebSocket runtime transport is no longer part
of the active architecture.

See [`docs/migration/developer_preview_migration.md`](docs/migration/developer_preview_migration.md)
for the modernization record and
[`docs/migration/developer_preview_readiness.md`](docs/migration/developer_preview_readiness.md)
for the current readiness report and
[`docs/decisions/embedded-preview-runtime-debugging.md`](docs/decisions/embedded-preview-runtime-debugging.md)
for the embedded-preview runtime-debugging contract.
