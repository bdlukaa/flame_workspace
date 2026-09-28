# ADR: Embedded Preview runtime-debugging contract

**Status:** Accepted
**Decision:** Embedded Web Preview follows contract A.

## Context

Flame Workspace starts the user's real Flutter Web application with
`flutter run -d web-server` and loads its served URL through the platform-neutral
`PreviewSurface`. Flutter's web-server target serves the app, but debug attachment
is conditional: current Flutter tooling may report that the Dart Debug Chrome
extension is required and may not provide a usable VM Service endpoint in the
embedded-preview workflow.

Flutter's supported machine/daemon integration is for IDEs and tools: its app
events can expose a VM Service WebSocket URI, DTD URI, DevTools URI, logs, and
restart/service-extension operations when the launched target provides those
capabilities. DTD and DevTools are tooling integrations, not alternate Flame
runtime transports. Chrome debug targets launch/debug through Flutter's browser
tooling and require a supported browser-debug configuration; they do not make
`web-server`'s URL alone equivalent to an attached debuggable browser target.
The Dart Debug Chrome extension is part of the browser-debugging path reported
by Flutter for web-server, not an extension Flame Workspace can safely assume is
installed in an arbitrary embedded browser.

## Decision

- Embedded Web Preview is for running the actual game, visual verification, and
  input iteration. It does not promise `ext.flameWorkspace.*` inspection or
  mutation.
- Runtime inspection, component/property mutation, scene switching, and pause /
  resume are available on Run targets when Workspace connects to their VM
  Service.
- Keep `ext.flameWorkspace.*` over VM Service as the sole runtime protocol. Do
  not add a custom Shelf/WebSocket protocol to compensate for web tooling limits.
- Flutter's process controls may still hot reload Web Preview. This is distinct
  from Workspace runtime inspection. Hot restart and Flame runtime controls are
  presented only for Run targets.
- Do not assume all future Flutter web toolchains have the same limitation. A
  future change to contract B requires a supported target path that exposes and
  reconnects to the VM Service from Workspace without depending on a particular
  `PreviewSurface` implementation, plus an end-to-end test against the real
  tooling.

## Consequences

The Web Preview can be useful even when VM Service attachment is unavailable.
Native (and other compatible Run) targets retain VM Service debugging. The UI
must indicate that runtime controls are Run-only rather than accepting actions
that can only fail because no runtime client exists.

## References

- [Flutter daemon protocol](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/doc/daemon.md)
- [Flutter and Dart DevTools](https://docs.flutter.dev/tools/devtools)
- [Run DevTools from the command line](https://docs.flutter.dev/tools/devtools/cli)
- [Flutter Web support](https://docs.flutter.dev/platform-integration/web)
