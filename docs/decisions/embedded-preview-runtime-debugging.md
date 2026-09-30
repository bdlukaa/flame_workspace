# ADR: Embedded Preview runtime-debugging contract

**Status:** Accepted
**Decision:** Embedded Web Preview is the only game execution workflow; it follows contract A (visual/input preview, runtime debugging only when genuinely available).

## Context

Flame Workspace launches the user's real Flutter Web app with
`flutter run -d web-server` and loads the served URL through the
platform-neutral `PreviewSurface`. Flutter's web-server target does not
consistently expose a usable VM Service endpoint. Browser debug attachment may
require the Dart Debug Chrome extension, which Workspace cannot assume is
installed in its embedded surface.

Flutter daemon, DTD, and DevTools are tooling integrations, not alternate Flame
runtime transports. A served URL alone is not equivalent to a debuggable Chrome
target. Workspace will not add an application-specific Shelf/WebSocket channel
to work around these limitations.

## Decision

- Preview executes the actual game and supports visual/input iteration, logs,
  stop, Flutter hot reload/restart, and embedded-surface reload through the
  runner and `PreviewSurface` boundaries.
- The editor has distinct **Build** and **Game** states. Build is the authored
  semantic scene model and its persisted/generated representation. Game is the
  live Flame instance. Runtime Inspector edits are transient overrides: they do
  not mutate or dirty Build State, are not persisted/generated, and are cleared
  by Stop.
- The hierarchy's **Local** view is authored Build State; **Runtime** is the
  actual tree returned by the game. Runtime-only objects remain runtime-only and
  are not copied into authored scenes automatically.
- Runtime inspection, mutation, scene switching, and pause/resume are available
  only when a real VM Service connection is established. The UI must not imply
  that those operations are available merely because Preview is running.
- `ext.flameWorkspace.*` over VM Service remains the sole runtime protocol.
- Build-State structural edits are persisted/generated and synchronized by
  explicitly reconstructing the selected Flame `World` after code reload. Hot
  reload alone is not treated as rerunning `onLoad`.
- Native game execution and native child-window embedding are intentionally
  unsupported for the current product phase. There is no separate Run workflow.
- Reconsider broader web runtime debugging only when supported Flutter tooling
  reliably provides a VM Service to Workspace and a real-tooling E2E test can
  demonstrate it without binding `PreviewSurface` to a specific WebView.

## Consequences

The embedded Web Preview remains useful when VM Service attachment is absent.
Native game execution is not offered as a fallback. Runtime controls are
available only after the editor has a live runtime client; otherwise they are
disabled or expose an actionable unavailable diagnostic. A running game does not
make runtime-only mutations part of authored data. Stop clears those overrides
and restores the authored Build view.

Single-frame Step is intentionally absent. Flame's public game-loop controls
provide pause/resume but do not expose a deterministic API to advance exactly
one update/render frame while paused. Workspace will not approximate stepping
with timers, delayed resume, or a second game loop.

## References

- [Flutter daemon protocol](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/doc/daemon.md)
- [Flutter and Dart DevTools](https://docs.flutter.dev/tools/devtools)
- [Run DevTools from the command line](https://docs.flutter.dev/tools/devtools/cli)
- [Flutter Web support](https://docs.flutter.dev/platform-integration/web)
