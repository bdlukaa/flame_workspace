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
  stop, hot reload, and hot restart through Flutter's process controls.
- Runtime inspection, mutation, and scene switching are available only when a
  real VM Service connection is established. The UI must not imply that those
  operations are available merely because Preview is running.
- `ext.flameWorkspace.*` over VM Service remains the sole runtime protocol.
- Native game execution and native child-window embedding are intentionally
  unsupported for the current product phase. There is no separate Run workflow.
- Reconsider broader web runtime debugging only when supported Flutter tooling
  reliably provides a VM Service to Workspace and a real-tooling E2E test can
  demonstrate it without binding `PreviewSurface` to a specific WebView.

## Consequences

The embedded Web Preview remains useful when VM Service attachment is absent.
Native game execution is not offered as a fallback. Runtime controls are
available only after the editor has a live runtime client; they must never fake
connection success or silently fail.

## References

- [Flutter daemon protocol](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/doc/daemon.md)
- [Flutter and Dart DevTools](https://docs.flutter.dev/tools/devtools)
- [Run DevTools from the command line](https://docs.flutter.dev/tools/devtools/cli)
- [Flutter Web support](https://docs.flutter.dev/platform-integration/web)
