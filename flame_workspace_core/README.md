# `flame_workspace_core`

This package is a compatibility facade for older Flame projects that still
import `flame_workspace_core`.

New projects should depend on [`flame_workspace_runtime`](../flame_workspace_runtime)
directly. The facade exports the current runtime and protocol APIs and does not
contain a separate server, WebSocket transport, scene system, or editor
implementation.

The active runtime communication path is the Dart VM Service. A game registers
stable `ext.flameWorkspace.*` extensions through
`FlameWorkspaceCore.ensureInitialized`, and the editor invokes them through
`flame_workspace_communication_bridge`.

The package remains intentionally small so existing projects can migrate their
import and dependency at a controlled boundary.
