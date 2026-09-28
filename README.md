# Flame Workspace

Flame Workspace is a visual development environment for normal Flutter + Flame
projects. Flame remains the runtime engine and Dart remains the source of game
behavior; Workspace owns project analysis, scene composition, editing, and
preview orchestration.

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
- discover Flutter targets and run through the cross-platform project runner;
- launch a web-server preview through the `PreviewSurface` abstraction;
- connect native runs to the stable `ext.flameWorkspace.*` VM Service API;
- hot reload, hot restart, log, and clean up Flutter processes.

### Experimental and platform-limited

- The embedded CEF preview surface is currently supported by the checked-in
  Windows desktop host. macOS and Linux host integration still require native
  runner setup and CEF toolchain validation.
- Flutter `web-server` preview reaches a usable localhost URL in the current
  environment, but Flutter does not expose a VM Service URL there without the
  Dart Debug Chrome extension. The end-to-end test records this as an explicit
  capability skip rather than claiming web runtime synchronization works.
- Native child-window embedding is retained only for the existing Windows
  Native Run path. Other discovered targets run in their normal Flutter host or
  device window.
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
  VM Service extensions installed into user games.
- `flame_workspace_communication_bridge/` — editor-side VM Service connection
  and invocation helpers.
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

Game Preview or Native Run
        │
        ▼
Flutter process runner
        │
        ▼
Dart VM Service
        │
        ▼
flame_workspace_runtime → Flame World/component tree
```

Workspace communicates with a running game through stable structured extensions
such as `ext.flameWorkspace.getState`, `getComponentTree`, `setProperty`, and
`setTransform`. The obsolete Shelf/WebSocket runtime transport is no longer part
of the active architecture.

See [`docs/migration/developer_preview_migration.md`](docs/migration/developer_preview_migration.md)
for the modernization record and
[`docs/migration/developer_preview_readiness.md`](docs/migration/developer_preview_readiness.md)
for the current readiness report.
