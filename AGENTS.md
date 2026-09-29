# Flame Workspace — Agent Instructions

## 1. Project Overview

Flame Workspace is a visual development environment for building games with [Flame](https://flame-engine.org/) and Flutter.

Flame is the game engine. Flame Workspace is **not** a replacement for Flame and must not evolve into a separate game engine.

The purpose of Flame Workspace is to provide an IDE/editor experience around normal Flame projects, including:

- project creation and management;
- scene management;
- visual scene editing;
- component hierarchy inspection;
- component creation and configuration;
- property inspection and editing;
- asset management;
- code generation;
- project analysis;
- game preview;
- hot reload and hot restart;
- runtime inspection and debugging;
- launching the user's game through embedded Flutter Web Preview.

A project created or edited with Flame Workspace should remain a normal Flutter + Flame project.

Users must be able to stop using Flame Workspace and continue developing their project using standard Flutter/Dart tooling.

---

# 2. Current Goal: Developer Preview

The immediate objective of this repository is the **Developer Preview** milestone.

Prioritize completing a coherent end-to-end workflow over adding more editor features.

The target workflow is:

```text
Create/Open Project
        ↓
Analyze Project
        ↓
Discover Scenes and Components
        ↓
Open Scene
        ↓
Inspect Component Hierarchy
        ↓
Select Component
        ↓
Edit Basic Properties
        ↓
Move/Resize/Rotate Visually
        ↓
Persist Changes
        ↓
Preview Game
        ↓
Hot Reload / Hot Restart
```

A feature that does not materially improve this workflow should generally be deferred until after Developer Preview.

Do not expand Developer Preview into a complete Unity/Godot-style editor.

Unless explicitly requested, Developer Preview does **not** require:

- animation editor;
- tilemap editor;
- physics editor;
- shader editor;
- visual scripting;
- prefab system;
- plugin marketplace;
- multiplayer collaboration;
- complete source-code IDE;
- advanced profiler;
- arbitrary custom inspectors;
- full mobile-device embedding;
- sophisticated asset pipelines.

Prefer a small workflow that works reliably over many partially implemented systems.

---

# 3. Architectural Principles

These principles are project invariants.

Do not violate them without explicit approval.

## 3.1 Flame Owns Runtime Behavior

Flame is responsible for:

- component lifecycle;
- rendering;
- input;
- collision detection;
- camera behavior;
- worlds;
- routing;
- effects;
- timers;
- game loop;
- other runtime game-engine behavior.

Flame Workspace should integrate with these APIs rather than recreate them.

Do not implement Workspace-specific alternatives to existing Flame functionality unless there is a compelling editor-specific reason.

---

## 3.2 Flame Workspace Is an Editor

Think of the architecture as:

```text
                  Flame Workspace
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
     Analyzer      Workspace Model    Generator
        │               │                │
        │               ▼                │
        │          Scene Editor           │
        │                                │
        └──────────── Runtime Protocol ──┘
                         │
                         ▼
                    Flame Project
                         │
                         ▼
                       Flame
```

The editor should understand and manipulate Flame projects without becoming their runtime.

---

## 3.3 No Vendor Lock-In

A generated project must remain understandable and maintainable without Flame Workspace.

Avoid requiring proprietary runtime behavior for ordinary game functionality.

Workspace-specific runtime code should exist only where editor/debug integration requires it.

Generated code should be:

- valid Dart;
- formatted;
- readable;
- reproducible;
- clearly separated from developer-owned code.

---

# 4. Package Boundaries

The desired dependency direction is:

```text
flame_workspace
      │
      ▼
flame_workspace_protocol
      ▲
      │
flame_workspace_runtime
      ▲
      │
   user game
```

Conceptually:

### `flame_workspace`

Contains editor functionality:

- Flutter UI;
- project explorer;
- scene editor;
- inspector;
- project analysis;
- Dart Analyzer integration;
- code generation;
- preview orchestration;
- Flutter process management;
- VM Service client.

### `flame_workspace_protocol`

Contains editor/runtime communication contracts:

- message models;
- serialization;
- protocol constants;
- request/response types.

It must remain lightweight.

### `flame_workspace_runtime`

Contains functionality installed into games for development-time integration:

- VM Service extensions;
- component inspection;
- scene inspection;
- property mutation;
- editor/runtime synchronization.

The runtime package must **never depend on the editor package**.

Circular package dependencies are prohibited.

---

# 5. Workspace Semantic Model

The editor must not use arbitrary Dart source code as its primary mutable scene representation.

Introduce and maintain a semantic Workspace model representing concepts such as:

```text
WorkspaceProject
SceneDefinition
ComponentDefinition
ComponentInstance
PropertyDefinition
AssetDefinition
Transform
```

The exact classes may evolve.

The important rule is:

```text
Dart/Flame project
       ↓
     Analyzer
       ↓
Workspace Semantic Model
       ↓
 ┌─────┴─────┐
 ▼           ▼
Editor    Generator
```

The UI should interact primarily with this model.

Avoid coupling widgets directly to Analyzer AST nodes.

---

# 6. Scene Data vs Behavior

Maintain a clear conceptual distinction:

```text
WHAT exists and WHERE it is
            vs
HOW it behaves
```

Scene composition belongs to Workspace's scene representation.

Examples:

- component type;
- component identifier;
- position;
- size;
- angle;
- anchor;
- priority;
- editable constructor/property values.

Behavior belongs in developer Dart code.

Examples:

```dart
class Player extends SpriteComponent {
  @override
  void update(double dt) {
    // Developer behavior.
  }
}
```

Do not attempt to turn arbitrary game logic into visual scene data.

---

# 7. Developer-Owned Source Code

Treat developer source code as user data.

Do not destructively rewrite developer-owned Dart files unless there is no reasonable alternative.

Prefer:

```text
scene.workspace.yaml
        ↓
generator
        ↓
scene.g.dart
```

over repeatedly modifying:

```text
scene.dart
```

Generated files should follow recognizable conventions such as:

```text
*.g.dart
```

or another clearly documented generated location.

Generated files must include an appropriate generated-file warning.

Generation must be deterministic whenever practical.

Running generation twice without input changes should produce no meaningful diff.

---

# 8. Dart Analysis

Use semantic Dart analysis for understanding projects.

Prefer the Dart Analyzer resolved model, including concepts such as:

```text
AnalysisContextCollection
ResolvedLibraryResult
LibraryElement
ClassElement
ConstructorElement
PropertyAccessorElement
InterfaceType
```

Use the currently supported Analyzer APIs where names differ.

Do not rely on source-text matching for semantic questions.

Bad:

```dart
source.contains('extends PositionComponent')
```

Bad:

```dart
extendsName == 'PositionComponent'
```

Good:

```text
resolve class
    ↓
inspect its type hierarchy
    ↓
determine whether PositionComponent is an ancestor
```

This must correctly support:

```dart
class Enemy extends PositionComponent {}

class Boss extends Enemy {}

class FinalBoss extends Boss {}
```

All three should be understood as PositionComponent descendants.

---

# 9. Flame API Discovery

Do not maintain large manually written snapshots of Flame's public API when that information can be discovered from the project's installed dependencies.

Avoid static catalogs equivalent to:

```text
built_in_components.dart
built_in_mixins.dart
```

as the authoritative source of Flame APIs.

Instead inspect the Flame version actually installed by the user's project.

Relevant information includes:

- classes;
- constructors;
- constructor parameters;
- inheritance;
- mixins;
- properties;
- types;
- annotations where relevant.

Flame Workspace should tolerate projects using different compatible Flame versions whenever reasonably possible.

---

# 10. Modern Flame Conventions

Use current stable Flame APIs unless compatibility requirements explicitly require otherwise.

Prefer modern APIs such as:

```text
World
CameraComponent
FlameGame<W extends World>
HasGameReference<T>
RouterComponent
WorldRoute
```

Do not introduce deprecated Flame APIs into new code.

For example, prefer:

```dart
HasGameReference<MyGame>
```

instead of deprecated:

```dart
HasGameRef
```

Respect Flame lifecycle signatures.

For example:

```dart
Future<void> onLoad() async {}
```

is valid.

But:

```dart
Future<void> update(double dt) async {}
```

is incorrect.

Use:

```dart
void update(double dt) {}
```

Likewise rendering should remain synchronous:

```dart
void render(Canvas canvas) {}
```

Do not generate asynchronous `update` or `render` methods.

---

# 11. Scenes and Worlds

Workspace scenes should integrate naturally with Flame's `World` architecture.

A Workspace scene may be represented as a `World` or a compatible abstraction.

Do not create an independent scene graph that competes with Flame's component tree at runtime.

Support native Flame navigation patterns where practical, including:

```text
World
CameraComponent
RouterComponent
WorldRoute
```

Workspace-specific scene switching must not make normal Flame routing impossible.

---

# 12. Scene Editor

The editor's Scene View and the running game are different concepts.

### Scene View

The Scene View exists for editing.

It should eventually support:

- selection;
- translation;
- resizing;
- rotation;
- zoom;
- pan;
- component outlines;
- hierarchy synchronization;
- grid snapping;
- guides;
- multi-selection.

Developer Preview only requires a reliable subset.

### Game Preview

The Game Preview executes the user's actual game.

Do not confuse Scene View with Game Preview.

---

# 13. Game Preview Architecture

Do not make native child-window embedding a core architectural dependency.

Avoid depending on OS-specific approaches such as:

```text
HWND parenting
NSWindow parenting
GtkWindow parenting
```

for the primary preview implementation.

The preferred Developer Preview architecture is:

```text
Flame Workspace
       │
       ├── Scene View
       │      └── editor-owned rendering
       │
       └── Game Preview
              │
              ▼
       embedded web surface
              │
              ▼
      flutter run -d web-server
              │
              ▼
       user's actual game
```

The preview must execute the user's real Flutter + Flame application rather than an approximation of its runtime behavior.

---

# 14. Preview Execution

Flame Workspace currently has exactly one game execution workflow: embedded
Flutter Web Preview using `flutter run -d web-server`. Native game execution and
native game-window embedding are intentionally unsupported. Keep Scene View
(editor-owned editing) distinct from Game Preview (the user's actual game).

Web Preview supports visual/input iteration, logs, stop, hot reload, and hot
restart through Flutter's process controls. Runtime inspection is available only
when a real VM Service connection is present; never simulate it or add another
transport to compensate for web tooling limitations.

---

# 15. Preview Surface Abstraction

Do not tightly couple Workspace architecture to one WebView package.

Hide the implementation behind an abstraction.

Conceptually:

```dart
abstract interface class PreviewSurface {
  Future<void> load(Uri uri);

  Future<void> reload();

  Future<void> dispose();
}
```

Platform-specific implementations may use different browser technologies.

Prefer solutions that compose correctly with Flutter and support:

- pointer input;
- keyboard input;
- focus;
- resizing;
- clipping;
- overlays where possible.

---

# 16. Flutter Process Management

Process management must be encapsulated.

The editor should be able to:

```text
Start
Stop
Hot Reload
Hot Restart
Observe Logs
Detect Exit
Detect Startup Failure
```

Do not scatter `Process.start` calls throughout UI code.

Create a dedicated runner abstraction.

The runner must clean up child processes when:

- the user stops execution;
- the project closes;
- Workspace exits;
- preview startup fails.

Do not leave orphaned Flutter/Dart processes.

---

# 17. VM Service Communication

Use the Dart/Flutter VM Service as the primary debug/runtime integration mechanism whenever possible.

Do not maintain two competing runtime communication systems.

The legacy custom Shelf/WebSocket debug server should be considered migration code and should not receive new features unless explicitly requested.

Prefer a stable service-extension API.

For example:

```text
ext.flameWorkspace.getState
ext.flameWorkspace.getComponentTree
ext.flameWorkspace.setProperty
ext.flameWorkspace.addComponent
ext.flameWorkspace.removeComponent
ext.flameWorkspace.setTransform
ext.flameWorkspace.setScene
ext.flameWorkspace.pause
ext.flameWorkspace.resume
```

Prefer:

```text
stable extension name
+
structured JSON parameters
```

over dynamically registering extension names for individual scenes or components.

Protocol changes should be represented in `flame_workspace_protocol`.

---

# 18. Property Editing

Property editing should not require rewriting arbitrary developer code for every interaction.

For interactive operations such as dragging:

```text
pointer movement
      ↓
Workspace scene model
      ↓
Scene View updates immediately
```

Do not perform:

```text
pointer movement
      ↓
rewrite Dart
      ↓
hot reload
      ↓
wait
      ↓
render
```

for every frame of an editor interaction.

Persist/generate changes at appropriate boundaries.

---

# 19. Dependencies

Keep generated projects minimal.

A base project should not automatically depend on every Flame ecosystem package.

Do not include packages such as:

```text
flame_audio
flame_forge2d
flame_isolate
```

unless the project actually uses them or the template explicitly requires them.

Optional Flame packages may impose newer SDK constraints or introduce platform requirements.

Keep the base template as close as practical to:

```text
Flutter
Flame
Flame Workspace runtime
```

Additional capabilities should be opt-in.

---

# 20. Version Compatibility

Do not assume versions found in old repository files are authoritative.

This repository contains historical version references.

Before performing a dependency migration:

1. inspect the current repository;
2. inspect current package constraints;
3. determine current stable compatible versions;
4. check migration notes for major API changes;
5. update code and tests together.

Do not blindly bump dependency versions.

Do not downgrade current dependencies simply because an older file references an older version.

---

# 21. Cross-Platform Requirements

Flame Workspace is intended to be cross-platform.

Editor code must not unnecessarily assume:

```text
Windows
macOS
Linux
```

unless contained behind a platform abstraction.

Paths must use Dart path utilities.

Do not construct paths using hardcoded `/` or `\`.

Do not assume a specific Flutter executable location.

Do not assume the preview device is Windows.

Platform-specific implementations should expose platform-neutral interfaces to the rest of Workspace.

---

# 22. Error Handling

The editor must expect user projects to be broken.

Examples:

```text
syntax errors
missing packages
failed pub get
invalid generated files
unsupported Flame version
Flutter compilation failure
missing assets
runtime exceptions
preview crash
VM Service disconnect
```

A broken game project must not crash the Workspace editor.

Report actionable errors.

Where possible include:

- operation that failed;
- relevant project/file;
- command that failed;
- process exit code;
- useful stderr/stdout;
- suggested recovery action.

---

# 23. Testing Philosophy

Tests should validate meaningful behavior and user workflows.

Do not create tests merely to increase coverage.

Avoid low-value tests that primarily verify:

- hardcoded labels;
- literal UI strings;
- theme colors;
- constants;
- implementation details;
- trivial getters/setters;
- framework behavior.

Prefer tests that would catch real regressions.

---

# 24. Test Structure

Use the appropriate level of testing.

### Unit tests

For:

- semantic models;
- serializers;
- parsers;
- generators;
- protocol messages;
- path handling;
- component discovery.

### Widget tests

For meaningful editor behavior such as:

- selecting a hierarchy item updates Inspector;
- editing a property updates the model;
- changing scenes updates editor state;
- error states are recoverable.

### Integration tests

For complete Workspace workflows.

Integration tests are especially important for Developer Preview.

---

# 25. Fixture Projects

Maintain representative Flame fixture projects.

Examples:

```text
fixtures/
  empty_game/
  basic_components/
  custom_components/
  inheritance/
  multiple_scenes/
  routing/
  broken_project/
```

Add additional fixtures when they represent a meaningful compatibility case.

Fixture projects should remain intentionally small.

---

# 26. Generated-Code Validation

Whenever generator behavior changes, validate the generated project itself.

A successful generator test should not only compare strings.

Where practical:

```text
Generate project
      ↓
dart format
      ↓
flutter pub get
      ↓
flutter analyze
      ↓
flutter test
```

Generated Dart that looks correct but does not compile is a generator failure.

---

# 27. Developer Preview End-to-End Test

Maintain an automated test covering the core Developer Preview workflow.

Conceptually:

```text
1. Create temporary Workspace project.
2. Resolve dependencies.
3. Index project.
4. Create/open a scene.
5. Add a component.
6. Modify component properties.
7. Persist/generate project state.
8. Format generated sources.
9. Run Flutter analyzer.
10. Run project tests.
11. Start preview.
12. Verify preview successfully starts.
13. Connect runtime/debug communication.
14. Perform at least one runtime operation.
15. Hot reload.
16. Stop preview.
17. Verify child processes terminate.
```

As the architecture becomes capable of supporting these steps, extend this test rather than replacing it with isolated mocks.

This test is the primary regression guard for Developer Preview.

---

# 28. Testing Changes Made by Agents

Agents must test their own changes.

Do not claim a task is complete without executing the relevant validation.

At minimum, for affected Dart/Flutter packages, run the applicable commands:

```bash
dart format .
```

```bash
flutter analyze
```

```bash
flutter test
```

For large repositories, package-specific equivalents are acceptable while iterating.

Before completing architectural or cross-package work, run broader repository validation.

If a command cannot run, explicitly report:

- which command;
- why it could not run;
- what remains unverified.

Never silently skip failing tests.

---

# 29. Fixing Failures

When tests fail after a change:

1. determine whether the implementation or test is incorrect;
2. fix the root cause;
3. rerun the relevant test;
4. rerun nearby tests when appropriate.

Do not weaken tests simply to make them pass.

Do not:

```text
skip
disable
delete
loosen assertion
increase arbitrary delay
```

without establishing that the test itself is incorrect or obsolete.

---

# 30. Async and Integration Tests

Avoid arbitrary timing assumptions.

Bad:

```dart
await Future.delayed(const Duration(seconds: 5));
```

Prefer waiting for observable state:

```text
process reports ready
VM Service becomes available
expected file appears
specific event arrives
component reaches expected state
```

All process/network waits must have reasonable timeouts and useful failure messages.

---

# 31. Mocks

Prefer real implementations for integration boundaries when reasonably cheap.

Do not mock the Dart Analyzer when testing project analysis.

Do not mock generated Dart compilation when testing generators.

Do not mock Flutter process management in the end-to-end test.

Mocks are appropriate for focused unit tests, not as substitutes for validating the actual development workflow.

---

# 32. Agent Workflow

Before changing code:

1. read this file;
2. inspect the relevant package;
3. inspect nearby tests;
4. understand current behavior;
5. identify the smallest architectural boundary affected.

Do not immediately start editing based solely on an issue description.

---

# 33. Scope Control

Keep each task focused.

If asked to:

> Improve component discovery.

Do not simultaneously:

- redesign the Inspector;
- migrate preview architecture;
- rename unrelated classes;
- reorganize the repository;
- change formatting conventions.

If another architectural problem blocks the task, explain the dependency before broadening scope.

Small, independently verifiable changes are preferred.

---

# 34. Refactoring

Refactoring is encouraged when it directly improves the requested work.

Avoid opportunistic repository-wide refactors.

When performing substantial refactoring:

1. preserve behavior with tests;
2. make structural changes;
3. verify tests;
4. then add new behavior.

Avoid mixing massive mechanical changes with new functionality in one change.

---

# 35. Dead and Legacy Code

This repository contains experimental implementations from earlier architectural iterations.

Do not assume existing code represents the desired architecture.

When encountering:

- old WebSocket communication;
- native-window preview experiments;
- static Flame metadata;
- deprecated Flame APIs;
- Windows-specific assumptions;
- abandoned generated-code approaches;

determine whether they are still part of the intended architecture before extending them.

Prefer deleting obsolete architecture once its replacement is working and tested.

Do not maintain two permanent implementations of the same subsystem.

---

# 36. TODOs

Do not add vague TODOs.

Bad:

```dart
// TODO: fix this
```

Better:

```dart
// TODO(flame-workspace): Replace the temporary web preview URL parser
// with structured Flutter daemon events once preview startup uses the
// daemon protocol.
```

A TODO should communicate:

- what remains;
- why it remains;
- what would allow it to be removed.

---

# 37. Documentation

Update documentation when changing:

- architecture;
- project format;
- generated files;
- runtime protocol;
- setup requirements;
- preview behavior;
- supported platforms;
- Developer Preview capabilities.

Do not document aspirational functionality as implemented.

Clearly distinguish:

```text
implemented
experimental
planned
```

---

# 38. Performance

The Scene View should feel interactive.

Do not trigger expensive operations such as:

```text
full project analysis
source generation
flutter analyze
hot reload
filesystem-wide scanning
```

for every pointer movement or property slider update.

Interactive editor operations should update in-memory state first.

Expensive persistence and validation should occur at deliberate boundaries and may be debounced where appropriate.

---

# 39. Logging

Use structured project logging rather than scattered `print` statements.

Important subsystems should provide enough context to diagnose:

```text
project loading
analysis
generation
Flutter processes
preview
VM Service
runtime protocol
filesystem watching
```

Avoid excessively verbose logs during normal operation.

---

# 40. Security and Project Trust

Treat opened projects as potentially untrusted.

Opening/indexing a project should not automatically execute arbitrary project code.

Operations that execute project code include actions such as:

```text
Preview
Run
Tests
Build
```

Keep static project analysis separate from runtime execution.

Do not execute generated shell commands constructed from unvalidated project content.

---

# 41. Completion Criteria

A code task is not complete merely because code was written.

Before reporting completion:

- format affected code;
- run static analysis;
- run relevant tests;
- inspect failures;
- verify generated output when applicable;
- verify cross-package implications when applicable;
- remove obsolete code introduced/replaced by the task;
- summarize remaining limitations.

For UI work, also verify the actual interaction rather than relying only on static analysis.

For generated project changes, compile/analyze a generated fixture.

For preview changes, actually launch a preview when the environment permits it.

---

# 42. Decision Priority

When architectural choices conflict, optimize in this order:

1. **Correctness**
2. **Developer project safety**
3. **Compatibility with normal Flame projects**
4. **Architectural simplicity**
5. **Testability**
6. **Cross-platform behavior**
7. **Editor responsiveness**
8. **Developer experience**
9. **Implementation convenience**

Do not sacrifice project safety or Flame compatibility merely because another implementation is easier.

---

# 43. Developer Preview Definition of Done

Developer Preview is reached when a developer can reliably:

```text
Create or open a Flame project
        ↓
Workspace understands the project
        ↓
Open a scene
        ↓
See its component hierarchy
        ↓
Select a component
        ↓
Inspect useful properties
        ↓
Edit basic properties
        ↓
Visually manipulate basic PositionComponents
        ↓
Persist those changes
        ↓
Run an embedded game preview
        ↓
Hot reload / restart
        ↓
See runtime errors/logs
```

This workflow must be covered by meaningful automated tests and at least one end-to-end fixture.

Developer Preview does **not** mean that every Flame feature has a visual editor.

---

# 44. Guiding Question

When uncertain whether a feature or architectural decision belongs in Flame Workspace, ask:

> Does this make it easier to build a normal Flame game visually while preserving Flame as the engine and Dart as the source of game behavior?

If yes, it likely belongs in Workspace.

If it requires Flame Workspace to become its own game engine, runtime, or proprietary application format, reconsider the approach.
