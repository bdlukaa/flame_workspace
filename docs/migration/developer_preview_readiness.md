# Developer Preview readiness report

**Review date:** 2026-09-28
**Toolchain:** Flutter 3.47.5, Dart 3.13.4, DevTools 2.60.0
**Scope:** cleanup and readiness review; no major feature work

## Status summary

Developer Preview is a coherent development workflow on the validated macOS
host, but it is not yet a cross-platform release. The semantic editor path,
generated-project path, native VM Service path, and process cleanup are working.
Embedded web preview reaches a usable URL, but the current Flutter web-server
configuration does not expose the VM Service without the Dart Debug Chrome
extension. CEF host integration is only present in the checked-in Windows
editor host.

## Implemented and verified

- Flutter project creation with a minimal Flutter + Flame + Workspace runtime
  dependency set.
- Analyzer-backed component and Flame API discovery, including multi-level
  `PositionComponent` inheritance and broken-source diagnostics.
- Workspace semantic scene model with stable IDs, hierarchy, transforms,
  properties, persistence, dirty state, undo/redo, and deterministic generated
  adapters.
- Scene View selection/navigation and basic PositionComponent transform editing.
- Basic asset discovery and semantic asset references.
- Cross-platform Flutter target discovery and shared process runner with start,
  stop, hot reload, hot restart, logs, state transitions, and cleanup.
- Stable VM Service runtime extensions under `ext.flameWorkspace.*` with
  structured requests and error responses.
- Compatibility facade in `flame_workspace_core` without an editor/runtime
  dependency cycle.
- No active Shelf/WebSocket runtime transport remains. No static
  `built_in_components.dart`, `built_in_mixins.dart`, or network-backed static
  Flame catalog remains.
- Generated source uses synchronous `void update(double dt)` and
  `void render(Canvas canvas)` lifecycle methods, and controlled code uses
  `HasGameReference` rather than `HasGameRef`.

## Working end-to-end flows

### Generated project workflow

`project_creator_integration_test.dart` created a fresh temporary project,
resolved dependencies, ran `flutter analyze` and `flutter test` inside that
project, reopened it through the importer, and indexed its generated component
and scene successfully.

`developer_preview_e2e_test.dart` additionally verified semantic scene edits,
persistence, deterministic adapter generation, formatting, generated-project
analysis, generated-project tests, reopen, and persisted transform/priority
values.

### Runtime workflow

On the available native desktop target, the end-to-end test connected to the
real VM Service, fetched game state and the Flame component tree, changed a
component property, hot reloaded, confirmed the process remained running, and
stopped it. The runner ended in `stopped` with `isRunning == false`.

### Web preview workflow

The real `flutter run -d web-server` process started, reported a localhost URL,
and was stopped through `PreviewProjectRunner`. The test intentionally skips
only the VM-specific portion when Flutter prints:

> The web-server device requires the Dart Debug Chrome extension for debugging.

This is an observed tooling capability limitation, not a simulated runtime
success.

## Validation results

- Full `flame_workspace` test suite: **52 passed, 1 intentional skip**.
- Developer Preview E2E suite: **2 passed, 1 intentional web VM skip**.
- Fresh project creator integration test: **passed**.
- `flame_workspace_runtime` tests: **7 passed**.
- `flame_workspace_communication_bridge` tests: **3 passed**.
- `flame_workspace_protocol` tests: **3 passed**.
- `flame_workspace_core` and checked-in `template` have no test directories.
- Fixture analysis: `empty_game`, `basic_components`, `inheritance`, and
  `multiple_worlds` analyze successfully. `broken_project` reports its two
  intentional syntax errors and remains usable for graceful-failure tests.
- `flame_workspace_core`, `flame_workspace_runtime`,
  `flame_workspace_communication_bridge`, and protocol analysis are clean.
- Editor analysis reports 22 existing Analyzer deprecation infos involving
  deprecated AST accessors (`name`, `members`, and `leftBracket`). The command
  exits nonzero because these infos are treated as issues; no new readiness
  errors were introduced.
- Template analysis reports three existing `unnecessary_overrides` infos in
  the checked-in example.
- `flutter pub get` succeeds for all maintained packages. The editor no longer
  declares the unused `process_run` dependency. The checked-in template keeps
  `window_manager` because its `MyGame` explicitly uses `WindowListener`;
  generated projects do not add it by default.

## Unsupported or limited areas

- Embedded CEF preview is currently validated only by the checked-in Windows
  desktop host. macOS and Linux native editor host projects and CEF toolchain
  setup are not present.
- Web-server preview does not provide runtime VM Service synchronization in the
  current environment without the Dart Debug Chrome extension.
- Native child-window embedding remains Windows-only and is separate from the
  platform-neutral web Preview abstraction. Other targets run in their normal
  Flutter host/device window.
- Android and iOS target execution was not validated on this macOS host because
  no such devices were available.
- Generic add/remove component operations require generated scene hooks, and
  generic property mutation requires generated property callbacks.
- Multi-selection, snapping, animation/tilemap/physics editors, visual
  scripting, full asset import, and source-code IDE features are not part of
  Developer Preview.
- The broken fixture is intentionally not expected to pass `flutter analyze`.
- The editor still has Analyzer API deprecation work remaining.

## Cleanup findings

- No live Shelf, WebSocket, `WorkbenchMessages`, or `IOWebSocketChannel` code
  was found.
- No static built-in Flame metadata files or consumers were found.
- No `HasGameRef` usage or asynchronous `update`/`render` lifecycle method was
  found in controlled source or generated output. Historical migration text
  still mentions the old forms as baseline findings.
- Windows-specific `flutter_native_view`/Win32 code is isolated to the Native
  Run embedding path and is documented as unsupported for other host targets.
- The compatibility-only `flame_workspace_core` facade remains intentionally
  because removing it would break existing imports; new projects use
  `flame_workspace_runtime`.
- Remaining TODOs concern non-Developer-Preview conveniences such as opening
  settings/docs/external editors, multiple-constructor support, and scaffolded
  developer behavior. They do not conceal a required path in the validated
  preview workflow.

## Recommended next three tasks

1. Replace the 22 deprecated Analyzer AST accessor usages with the current
   Analyzer APIs, then make editor analysis clean without suppressing real
   diagnostics.
2. Establish a supported web runtime-debug path: either document and integrate
   the Dart Debug Chrome extension/structured Flutter tooling or provide a
   tested web preview target that exposes the VM Service while preserving the
   single VM Service bridge.
3. Complete and validate non-Windows desktop host setup for the CEF Preview
   surface, then exercise target discovery and native Run on at least one
   additional desktop platform.
