/// Compatibility exports for projects that still depend on
/// `flame_workspace_core`.
///
/// New projects should depend on `flame_workspace_runtime` directly.
library;

export 'package:flame_workspace_protocol/messages.dart';
export 'package:flame_workspace_protocol/state.dart';
export 'package:flame_workspace_runtime/flame_workspace_runtime.dart';
