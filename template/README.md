# Flame Workspace template

This directory is a small, ordinary Flutter + Flame project. It is both the
checked-in reference project for Flame Workspace and a normal project that can
be built, tested, or continued with standard Flutter/Dart tooling.

It depends on Flutter, Flame, and `flame_workspace_runtime`; optional Flame
ecosystem packages are not required. To open it, start Flame Workspace and use
Open Project on this directory. To run it without Workspace:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Flame Workspace's Preview runs the actual app using `flutter run -d web-server`
and displays it in the embedded web surface. Native game execution and native
game-window embedding are not supported.

## Structure

```text
lib/
  main.dart                         Flutter entry point and runtime setup
  game.dart                         FlameGame and camera setup
  components/my_component.dart      Developer-owned Flame component
  scenes/level_one/                 World/scene and behavior source
  .generated/properties.dart       Generated property mutation bridge
  .generated/scenes.dart           Generated global scene dispatcher
  .generated/scenes/               Generated scene composition adapters
.flame_workspace/scenes/            Authored semantic scene documents
flame_configuration.yaml            Workspace project configuration
pubspec.yaml                        Flutter/Flame dependencies
```

Scene composition and game behavior are intentionally separate. The authored
scene document is Workspace Build State; its generated adapter populates a
`FlameScene` during `onLoad`. The scene and component Dart sources remain
developer-owned. Generated files are marked and should not be edited manually.

## Build and Game state in Workspace

In **Build** mode, edits to scene composition, transforms, properties, priority,
and background belong to the authored semantic model. Saving writes scene JSON
under `.flame_workspace/scenes/` and regenerates deterministic files under
`lib/.generated/`.

In **Game** mode, Workspace controls the running Flame instance. Runtime
property, transform, and scene-background edits are temporary overrides: they do not change saved scene
data and are cleared by Stop. **Local** hierarchy shows the authored scene;
**Runtime** hierarchy shows the tree returned by the running game, including
objects dynamically created by game behavior. Runtime-only objects are not
copied into the authored scene automatically.

Build-State structural changes require scene reconstruction in the running game.
Workspace reloads generated code and explicitly switches/recreates the selected
`World`; Flutter hot reload by itself does not rerun the current World's
`onLoad`.

## Runtime integration

`main.dart` initializes `flame_workspace_runtime`, which registers stable
`ext.flameWorkspace.*` VM Service extensions for state/tree inspection,
transforms, supported properties, scene switching, and pause/resume. These
features are available in Workspace only while a real VM Service connection is
established. Embedded web Preview can run without VM Service attachment, in
which case runtime inspection and editing controls are unavailable. No custom
WebSocket transport is used.

This runtime integration is optional development-time support. The project
remains an ordinary Flutter + Flame app and its normal game behavior does not
require Flame Workspace.

## Flame lifecycle conventions

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

`update` and `render` are synchronous Flame callbacks; `onLoad` may be
asynchronous.
