# Flame Workspace template

This directory is a small, ordinary Flutter + Flame project used for manual
preview checks and as a reference for projects created by Workspace.

It depends on Flutter, Flame, `flame_workspace_runtime`, and
`window_manager` for the checked-in desktop host's native window lifecycle.
Optional Flame ecosystem packages are not required, and projects created by
`ProjectCreator` omit `window_manager` unless their own game uses it.

## Structure

```text
lib/
  main.dart                         Flutter entry point and runtime setup
  game.dart                         FlameGame, World, and CameraComponent setup
  components/                       Developer-owned Flame components
  scenes/level_one/                 World/scene and behavior source
  .generated/                       Generated runtime hooks and adapters
pubspec.yaml                        Flutter/Flame dependencies
```

The scene is a Flame `World` through `FlameScene`. Scene composition is kept in
Workspace's semantic scene document and generated adapters; behavior remains in
Dart scene scripts and components. Generated files are marked and should not be
edited manually.

## Lifecycle conventions

Flame lifecycle methods follow the current synchronous/asynchronous contracts:

```dart
@override
Future<void> onLoad() async {
  await super.onLoad();
}

@override
void update(double dt) {
  super.update(dt);
}

@override
void render(Canvas canvas) {
  super.render(canvas);
}
```

`update` and `render` must not be asynchronous.

## Runtime integration

`main.dart` calls `FlameWorkspaceCore.ensureInitialized(game)`. The runtime
package registers stable `ext.flameWorkspace.*` VM Service extensions for state,
component-tree inspection, transforms, supported properties, scene changes, and
engine pause/resume. It is optional development-time integration; the game
remains a normal Flutter + Flame project without the editor.

Run the template with standard Flutter tooling:

```bash
flutter pub get
flutter analyze
flutter run
```
