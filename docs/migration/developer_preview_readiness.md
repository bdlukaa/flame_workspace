# Developer Preview readiness report

**Review date:** 2026-09-28
**Toolchain:** Flutter 3.47.5, Dart 3.13.4, DevTools 2.60.0
**Scope:** cleanup and readiness review; no major feature work

## Status summary

Developer Preview provides project analysis/editing and one game execution
workflow: the user's actual Flutter Web app embedded via CEF. Embedded Web
Preview is visual/input-only unless Flutter exposes a usable VM Service. Native
game execution and native child-window embedding are intentionally unsupported.

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
- A fixed Web Preview process runner with start, stop, hot reload, hot restart,
  logs, startup/exit state, and cleanup.
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

The former native VM Service Run workflow has been removed. The Web Preview
E2E verifies the supported process/URL/reload/stop workflow; runtime capability
is treated as unavailable unless a real VM Service connection exists.

### Web preview workflow

The real `flutter run -d web-server` process starts the actual user application,
reports a localhost URL, and is stopped through `PreviewProjectRunner`. The
embedded preview contract is intentionally visual/input-only. The Flutter
web-server can require the Dart Debug Chrome extension for browser debugging
and does not consistently provide a VM Service endpoint usable by Workspace's
embedded surface. The editor therefore does not claim runtime introspection when Web Preview
lacks a VM Service. No native Run target is offered.

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
These package-analysis counts above are from the historical review date, not a
claim about the current checkout. For the current execution contract, the
editor and generated template no longer use `window_manager` for native game
window management. Validate maintained packages using their current commands.

## Unsupported or limited areas

- Embedded CEF preview host support and platform toolchain requirements are
  documented separately; verify rendering and input on each host before release.
- Embedded Web Preview is visual/input-only unless a real VM Service is
  connected. Native game execution is intentionally unsupported. See
  [`../decisions/embedded-preview-runtime-debugging.md`](../decisions/embedded-preview-runtime-debugging.md).

- Generic add/remove component operations require generated scene hooks, and
  generic property mutation requires generated property callbacks.
- Multi-selection, snapping, animation/tilemap/physics editors, visual
  scripting, full asset import, and source-code IDE features are not part of
  Developer Preview.
- The broken fixture is intentionally not expected to pass `flutter analyze`.


## Cleanup findings

- No live Shelf, WebSocket, `WorkbenchMessages`, or `IOWebSocketChannel` code
  was found.
- No static built-in Flame metadata files or consumers were found.
- No `HasGameRef` usage or asynchronous `update`/`render` lifecycle method was
  found in controlled source or generated output. Historical migration text
  still mentions the old forms as baseline findings.
- Native game-window embedding, target discovery, and the `flutter_native_view`
  dependency have been removed. Standard Windows/macOS/Linux editor hosts remain.
- The compatibility-only `flame_workspace_core` facade remains intentionally
  because removing it would break existing imports; new projects use
  `flame_workspace_runtime`.
- Remaining TODOs concern non-Developer-Preview conveniences such as opening
  settings/docs/external editors, multiple-constructor support, and scaffolded
  developer behavior. They do not conceal a required path in the validated
  preview workflow.

## Recommended next three tasks

1. Revisit web runtime debugging only if Flutter supports a reliable external
   attachment path for the embedded target; preserve VM Service as the single
   runtime protocol.
2. Validate the CEF Preview surface's rendering, focus, and process cleanup on
   each supported desktop host.
3. Extend Preview E2E coverage for host-level input and process cleanup where
   those behaviors can be automated reliably.
