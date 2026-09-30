# Flame Workspace — Agent Instructions

## Purpose

Flame Workspace is a visual development environment for building normal Flutter + Flame games.

**Flame is the game engine. Flame Workspace is the editor.**

A project created or edited with Flame Workspace must remain understandable, maintainable, and runnable with standard Flutter/Dart/Flame tooling even if the developer stops using Flame Workspace.

Do not evolve Flame Workspace into a competing runtime, proprietary game format, or replacement for Flame.

---

# 1. Current Objective

The current milestone is a reliable **Developer Preview / Visual Editing Core**.

Prioritize the complete workflow:

```text
Create/Open Project
        ↓
Analyze Project
        ↓
Discover Scenes and Components
        ↓
Open Scene
        ↓
Inspect Hierarchy
        ↓
Add / Remove Components
        ↓
Edit Properties
        ↓
Move / Resize / Rotate / Scale
        ↓
Persist Authored State
        ↓
Play Actual Game
        ↓
Inspect Runtime
        ↓
Stop
        ↓
Return to Unchanged Build State
```

A smaller workflow that works reliably is better than many partially implemented editor systems.

Unless explicitly requested, defer:

- animation editor;
- tilemap editor;
- physics editor;
- shader editor;
- visual scripting;
- prefab system;
- plugin marketplace;
- advanced profiler;
- complete source-code IDE;
- sophisticated asset pipelines.

---

# 2. Decision Priority

When architectural choices conflict, optimize in this order:

1. correctness;
2. developer project safety;
3. normal Flame compatibility;
4. architectural simplicity;
5. testability;
6. cross-platform behavior;
7. editor responsiveness;
8. developer experience;
9. implementation convenience.

Do not sacrifice project safety or Flame compatibility merely because another implementation is easier.

---

# 3. Core Architectural Invariants

These rules are non-negotiable unless the task explicitly changes the architecture.

## 3.1 Flame owns runtime behavior

Flame owns:

- component lifecycle;
- rendering;
- input;
- game loop;
- collision detection;
- cameras;
- worlds;
- routing;
- effects;
- timers;
- runtime component trees.

Workspace integrates with Flame rather than reimplementing those systems.

---

## 3.2 The Workspace semantic model owns authored state

The authoritative authored pipeline is:

```text
Developer Dart / Flame API
          ↓
       Analyzer
          ↓
Workspace Semantic Model
          ↓
     Persistence
          ↓
      Generator
          ↓
   Normal Flame Game
```

The UI should primarily manipulate the Workspace semantic model.

Do not use Analyzer AST nodes as mutable editor state.

Do not use generated Dart as the primary editor database.

---

## 3.3 Build State and Game State are separate

### Build State

Build State is authored content.

It includes:

- scene composition;
- component hierarchy;
- transforms;
- editable properties;
- assets;
- scene properties;
- editor metadata where appropriate.

Build changes may:

- become dirty;
- participate in undo/redo;
- persist under `.flame_workspace`;
- regenerate Workspace-owned adapters.

### Game State

Game State is the actual running Flame game.

Runtime changes are transient.

They must **not implicitly**:

- mutate Build State;
- mark the project dirty;
- modify persisted scene data;
- regenerate authored adapters;
- rewrite developer source.

Stopping Game State must discard runtime-only overrides.

If a future feature allows copying a runtime value into Build State, that must be an explicit user action.

---

## 3.4 Canonical component identity

`ComponentInstance.id` is the canonical component identity across:

```text
semantic model
generated FlameKey
runtime protocol
hierarchy
selection
runtime reconciliation
property mutation
transform mutation
```

`declarationName` is display/source metadata only.

Never use `declarationName` as runtime identity.

---

## 3.5 Scene View and Game Preview are different

**Scene View** is an editor-owned representation of authored Build State.

**Game Preview** executes the user's actual Flutter + Flame application.

Do not make gameplay execution the source of truth for scene editing.

Do not make Build State depend on a runtime connection.

---

# 4. Typed Property Architecture

Raw Dart source strings are not semantic values.

Never store values such as:

```text
Anchor.center
Color(0xFFFFFFFF)
Vector2(10, 20)
Paint()..color = ...
```

as ordinary strings merely because they are valid Dart expressions.

The target property pipeline is:

```text
Analyzer type metadata
        ↓
Property Type Adapter
        ↓
Typed Workspace Value
        ↓
 ┌───────────────┬────────────────┐
 ↓               ↓                ↓
Inspector     Persistence     Code Generation
                                  ↓
                           Runtime Encoding
```

At minimum, common values should have explicit semantics for:

- null;
- String;
- bool;
- int;
- double / num;
- Color;
- Vector2;
- Anchor;
- enums;
- Paint;
- text styling structures;
- other structured types as support is added.

Do not infer a value's type from what its string representation looks like.

Example:

```text
String "40.0" ≠ double 40.0
```

Fix type mistakes where values enter the semantic model, not inside the Dart generator.

---

# 5. Property and Component Adapters

When behavior varies by data type or component type, prefer an adapter/capability abstraction over scattered special cases.

A property type adapter should conceptually own:

```text
parse
validate
display
JSON serialization
Dart expression generation
runtime encoding
editor metadata
```

Do not independently implement these rules in:

- Add Component;
- Inspector;
- generator;
- runtime protocol.

Likewise, component-specific behavior belongs in a component adapter/capability layer when generic property handling is insufficient.

Do not add one-off checks such as:

```dart
if (component is CircleComponent) ...
```

throughout unrelated layers when the behavior belongs in a reusable adapter.

---

# 6. Flame Component Support Contract

**Discovered does not mean supported.**

Flame Workspace should inspect the Flame version installed in the user's project and discover public API metadata dynamically.

However, a component may only be presented as normally addable when Workspace can construct it safely.

A supported component requires:

- a usable constructor;
- representations for all required constructor arguments;
- valid imports;
- valid generated Dart;
- persistence support;
- enough editor representation to make adding it meaningful.

If these requirements are not met:

- hide it from normal Add Component results, or
- display it disabled with a clear unsupported reason.

Never allow:

```text
Add Component
    ↓
valid-looking editor form
    ↓
Add
    ↓
generated project does not compile
```

Core visual component support should be tested explicitly.

Current core targets include:

- PositionComponent;
- SpriteComponent;
- CircleComponent;
- RectangleComponent;
- PolygonComponent;
- TextComponent;
- TextBoxComponent.

Do not claim additional components are supported merely because Flame exports them.

---

# 7. Flame API Discovery

Use semantic Dart analysis.

Prefer resolved Analyzer APIs such as:

```text
AnalysisContextCollection
ResolvedLibraryResult
LibraryElement
ClassElement
ConstructorElement
InterfaceType
```

Use current equivalent API names when Analyzer changes.

Do not answer semantic questions using source string matching.

Bad:

```dart
source.contains('extends PositionComponent')
```

Bad:

```dart
extendsName == 'PositionComponent'
```

Correct approach:

```text
resolve class
    ↓
inspect type hierarchy
    ↓
determine whether PositionComponent is an ancestor
```

This must correctly understand indirect inheritance.

Do not maintain a manually curated snapshot of the Flame API as the authoritative source when the installed dependency can be inspected.

---

# 8. Modern Flame Compatibility

Use the Flame API resolved by the user's project.

Prefer current Flame concepts such as:

- `World`;
- `CameraComponent`;
- `FlameGame<W extends World>`;
- `HasGameReference<T>`;
- `RouterComponent`;
- `WorldRoute`.

Do not introduce deprecated Flame APIs into new code without an explicit compatibility reason.

Respect Flame lifecycle signatures.

For example:

```dart
Future<void> onLoad() async {}
void update(double dt) {}
void render(Canvas canvas) {}
```

Do not generate asynchronous `update` or `render`.

---

# 9. Scene Composition vs Game Behavior

Maintain this distinction:

```text
WHAT exists / WHERE it is
          vs
HOW it behaves
```

Workspace scene data may describe:

- component type;
- semantic identity;
- hierarchy;
- position;
- size;
- scale;
- angle;
- anchor;
- priority;
- supported constructor values;
- supported editable properties;
- asset references.

Game behavior remains developer Dart code.

Do not attempt to serialize arbitrary `update`, input, collision, routing, or gameplay logic into visual scene data.

---

# 10. Developer-Owned Source

Treat developer source as user data.

Avoid destructively rewriting developer-owned Dart files.

Prefer Workspace-owned data and additive generated adapters.

Conceptually:

```text
.flame_workspace/scenes/...
        ↓
generator
        ↓
lib/.generated/...
```

Generated files must be:

- clearly marked as generated;
- deterministic;
- readable;
- formatted;
- replaceable;
- separated from developer-owned code.

Do not modify developer Dart continuously during editor interactions.

---

# 11. Dart Code Generation

Use structured generation for machine-generated Dart.

Prefer `package:code_builder` for:

- libraries;
- imports/references;
- declarations;
- constructor calls;
- named arguments;
- literals;
- static references;
- assignments;
- cascades where practical;
- generated functions and dispatchers.

The generation pipeline should be:

```text
Typed Workspace Value
        ↓
code_builder Expression / AST
        ↓
DartEmitter
        ↓
dart_style
        ↓
Analyzer validation
```

`code_builder` is an implementation detail of Flame Workspace.

Generated user projects must not depend on it.

### Do not

Do not build typed Dart values through arbitrary interpolation like:

```dart
'$name: $value'
```

Do not guess whether a string contains Dart source.

Do not silently call `.toString()` for unsupported semantic values.

Avoid raw `Code(...)` when a structured `code_builder` representation exists.

If raw code is unavoidable, isolate it behind the generation abstraction and document why.

### Generation failures

If a supported semantic value cannot be generated, fail before emitting broken source.

Include useful context where possible:

- scene;
- component ID;
- component type;
- property;
- semantic value type.

---

# 12. Import Generation

Prefer structured references and scoped allocation for generated Dart imports.

Generation must safely handle:

- Flame symbols;
- Flutter/Dart symbols;
- Workspace runtime symbols;
- project-defined component symbols;
- naming collisions.

Do not grow a second ad-hoc import-resolution system alongside `code_builder`.

Generated imports must remain deterministic.

---

# 13. Generated-Code Validation

Generator unit tests are not enough.

Whenever generator behavior changes, validate generated projects where practical:

```text
generate
   ↓
format
   ↓
analyze
   ↓
test where relevant
```

Generated Dart that looks correct but does not compile is a generator failure.

For supported components, maintain contract tests covering:

```text
discover
→ construct semantic value
→ generate
→ analyze
→ persist/reopen
```

Include regression tests for type-sensitive values such as:

```text
double 40.0 → 40.0
String "40.0" → '40.0'
Color → valid Color expression
Anchor → valid static/member expression
Vector2 → valid constructor expression
Paint → valid structured expression
```

---

# 14. Structural Scene Changes

Do not assume Flutter hot reload reruns Flame `onLoad`.

Structural changes such as:

- add;
- remove;
- reparent;
- component type change;
- relevant ordering changes;

must use an explicit deterministic synchronization/reconstruction path.

Classify changes centrally rather than letting individual widgets guess whether to:

- mutate runtime directly;
- reconstruct a scene;
- hot reload;
- hot restart.

Build State remains authoritative even if runtime synchronization fails.

---

# 15. Runtime Protocol

Use the Dart/Flutter VM Service as the primary runtime/debug integration mechanism when available.

Do not maintain multiple competing debug transports.

Legacy custom Shelf/WebSocket infrastructure is migration code unless explicitly revived.

Use stable service extensions with structured parameters.

Examples may include:

```text
ext.flameWorkspace.getState
ext.flameWorkspace.getComponentTree
ext.flameWorkspace.setProperty
ext.flameWorkspace.setTransform
ext.flameWorkspace.setScene
ext.flameWorkspace.pause
ext.flameWorkspace.resume
```

The exact supported set should match implementation.

Do not document obsolete service extensions as active.

Protocol contracts belong in `flame_workspace_protocol`.

The runtime package must never depend on the editor package.

---

# 16. Runtime Reconciliation

When runtime inspection is available, compare the live Flame component tree with authored Build State.

Detect meaningful mismatches such as:

- expected component missing;
- unexpected runtime-only component;
- duplicate semantic IDs;
- type mismatch;
- hierarchy mismatch.

Do not wait for a later `component_not_found` to reveal a known synchronization failure.

Runtime-only dynamically spawned components must not automatically become authored Build State components.

---

# 17. Preview Architecture

The primary game execution workflow is embedded Flutter Web Preview using:

```text
flutter run -d web-server
```

Do not make native child-window embedding a core dependency.

Keep WebView/browser implementation details behind an abstraction.

The preview should support, where available:

- start;
- stop;
- reload;
- hot reload;
- hot restart;
- logs;
- process-exit detection;
- runtime/debug control.

Runtime mutation is available only when a real supported debug connection exists.

Do not create another transport merely to simulate unavailable VM Service functionality.

---

# 18. Flutter Process Management

Process management belongs behind a runner abstraction.

Do not scatter `Process.start` throughout widgets.

The runner must clean up child processes when:

- preview stops;
- project closes;
- Workspace exits;
- startup fails.

Do not leave orphaned Flutter or Dart processes.

Wait for observable readiness rather than arbitrary delays.

Bad:

```dart
await Future.delayed(const Duration(seconds: 5));
```

Prefer:

```text
process reports ready
VM Service appears
expected event arrives
specific state becomes true
```

All waits require reasonable timeouts and useful failure messages.

---

# 19. Editor Interaction Performance

Interactive operations must update in-memory authored state first.

Do not trigger expensive work for every pointer movement.

Avoid per-frame:

- source generation;
- project-wide analysis;
- `flutter analyze`;
- hot reload;
- filesystem-wide scanning.

Persist, generate, synchronize, and validate at deliberate boundaries.

---

# 20. Undo / Redo

Build-State mutations should travel through a coherent editing transaction system.

Undo/redo must preserve semantic correctness and synchronize the preview through the same synchronization strategy as the original edit.

Game-State runtime overrides do not belong in Build-State undo history.

Do not create separate history logic for each widget.

---

# 21. Assets

Keep generated projects minimal.

Base projects should generally depend on:

```text
Flutter
Flame
Flame Workspace runtime
```

Optional Flame ecosystem packages should only be added when actually required.

Asset operations must respect `pubspec.yaml`.

Do not silently rewrite user project configuration unless the operation explicitly owns that change.

---

# 22. Cross-Platform Rules

Flame Workspace targets desktop environments without unnecessary platform coupling.

Do not assume Windows, macOS, or Linux except inside a platform-specific implementation.

Use `package:path` for filesystem paths.

Do not:

- hardcode `/` or `\`;
- assume Flutter's executable path;
- assume a specific preview host platform.

Platform-specific implementations must expose platform-neutral interfaces.

---

# 23. Project Trust

Treat opened projects as potentially untrusted.

Static indexing must not automatically execute project code.

Actions that execute project code include:

- Preview;
- Run;
- Tests;
- Build.

Keep static project analysis distinct from runtime execution.

Never construct unsafe shell commands from unvalidated project data.

---

# 24. Error Handling

User projects may be broken.

Expected failure cases include:

- syntax errors;
- missing dependencies;
- failed `pub get`;
- invalid assets;
- unsupported Flame versions;
- generated-code failures;
- preview compilation failures;
- runtime exceptions;
- VM Service disconnects.

A broken game project must not crash Flame Workspace.

Errors should be actionable and, where relevant, include:

- operation;
- project/file;
- component/property context;
- command;
- exit code;
- useful stdout/stderr;
- recovery action.

No editable control should silently do nothing.

---

# 25. Testing Strategy

Tests exist to catch user-visible or architectural regressions, not inflate coverage.

## Unit tests

Use for:

- semantic models;
- typed values;
- adapters;
- serializers;
- parsers;
- generators;
- protocol messages;
- component discovery;
- transform/grid math.

## Widget tests

Use for meaningful editor behavior, such as:

- hierarchy selection updates Inspector;
- property edits update semantic state;
- invalid values are rejected;
- Build/Game controls expose correct state;
- errors remain recoverable.

## Integration tests

Use for real workflows across subsystem boundaries.

Prefer real implementations at integration boundaries.

Do not mock:

- Dart Analyzer when testing project analysis;
- generated code compilation when testing generators;
- actual process management in the primary E2E test.

---

# 26. Core End-to-End Regression

Maintain at least one automated test covering:

```text
Create/Open Project
→ index
→ open scene
→ inspect hierarchy
→ add supported component
→ edit properties
→ transform component
→ persist
→ generate
→ format/analyze
→ start preview
→ reconcile runtime
→ mutate runtime
→ Stop
→ verify Build State unchanged
→ reopen
→ verify authored values
```

Also retain a specific Play Mode isolation scenario:

```text
Build value = A
→ Play
→ runtime value = B
→ Stop
→ Build value still = A
→ Play again
→ runtime starts at A
```

These are primary architectural regression guards.

---

# 27. Marionette UI Verification

When Marionette integration is available, use it for real editor workflow validation.

Marionette supplements tests; it does not replace them.

For editor-facing changes, prefer:

```text
focused tests
→ flutter analyze
→ launch Flame Workspace
→ connect Marionette
→ interact with actual UI
→ inspect diagnostics/logs
→ screenshot when visual behavior matters
```

Important editor controls should expose stable, meaningful `Key` and/or Semantics identifiers when practical.

Do not build test-only UI APIs that bypass the actual workflow being tested.

Diagnostic custom extensions are appropriate for observing internal state.

UI operations should still exercise real UI where that behavior is under test.

---

# 28. Agent Workflow

Before editing:

1. read this file;
2. inspect the relevant implementation;
3. inspect nearby tests;
4. trace the real flow end-to-end;
5. identify the smallest architectural boundary that owns the problem.

Then apply the repository's efficiency ladder:

1. does this need to exist?
2. does the repository already solve it?
3. does Dart/Flutter/Flame already solve it?
4. does an installed dependency solve it?
5. can an existing abstraction be extended?
6. only then add the minimum new code.

A bug report usually describes a symptom.

Trace sibling callers and fix the shared root cause once.

---

# 29. Scope Control

Keep tasks focused.

Do not turn a request such as:

> Fix CircleComponent radius generation.

into:

- an Inspector redesign;
- a preview migration;
- repository-wide renaming;
- unrelated formatting cleanup.

However, if the root cause is shared—for example the semantic value system—fix the shared abstraction rather than patching only `CircleComponent`.

Prefer small independently verifiable changes.

---

# 30. Refactoring

Refactor when it directly supports the requested change.

For substantial refactors:

1. characterize current behavior with tests;
2. change structure;
3. restore green tests;
4. add new behavior.

Do not mix broad mechanical cleanup with unrelated functionality.

Do not preserve obsolete APIs solely because they already exist.

---

# 31. Legacy Code

This repository contains remnants of earlier architectural iterations.

Examples may include:

- custom WebSocket debugging;
- native-window preview experiments;
- static Flame API snapshots;
- deprecated APIs;
- old scene mutation hooks;
- old generated-code approaches.

Before extending old code, determine whether it belongs to the current architecture.

When a replacement is working and tested, prefer deleting obsolete architecture over maintaining two implementations.

---

# 32. Dependencies

Before dependency changes:

1. inspect current constraints;
2. inspect actual usage;
3. verify compatible current versions;
4. review migration implications;
5. update tests with the dependency.

Do not upgrade or downgrade blindly based on stale repository references.

Dependencies used only for Workspace implementation, such as `code_builder`, should not leak into generated game projects.

---

# 33. Documentation

Update documentation when changing:

- architecture;
- persisted project format;
- generated files;
- runtime protocol;
- supported component capabilities;
- preview behavior;
- platform support;
- setup requirements.

Document reality, not aspiration.

Use clear states:

```text
implemented
experimental
unsupported
planned
```

---

# 34. Logging

Prefer structured subsystem logging over scattered `print`.

Important logs should identify enough context for:

- project loading;
- Analyzer;
- generation;
- preview process;
- VM Service;
- runtime reconciliation;
- filesystem watching.

Avoid noisy success logging during ordinary editor interactions.

---

# 35. TODOs

Do not add vague TODOs.

Bad:

```dart
// TODO: fix this
```

A useful TODO explains:

- what remains;
- why;
- what condition allows removal.

If the work should be completed as part of the current task, do not replace implementation with a TODO.

---

# 36. Completion Criteria

A task is not complete because code was written.

Before completion, run the relevant validation.

At minimum where applicable:

```bash
dart format .
flutter analyze
flutter test
```

Use package-specific commands while iterating when appropriate.

For generator changes:

```text
generate fixture
→ format
→ analyze generated project
```

For preview changes:

```text
actually start preview
```

when the environment permits.

For UI changes:

```text
exercise the actual interaction
```

and use Marionette when available.

If validation cannot run, report explicitly:

- command not run;
- reason;
- what remains unverified.

Never silently skip failing tests.

Do not weaken or delete tests merely to make them pass.

---

# 37. Definition of Done for a Supported Component

If Flame Workspace presents a Flame component as supported, this workflow must succeed:

```text
select component
→ configure required constructor values
→ Add
→ generated code compiles
→ component appears in Build State
→ edit supported properties
→ generated code still compiles
→ save
→ reopen
→ authored values preserved
→ Play
→ runtime matches authored state
→ runtime-only edits remain transient
→ Stop
→ Build State remains correct
```

If this contract cannot be satisfied, classify the component as unsupported or partially supported instead of pretending otherwise.

---

# 38. Guiding Question

When unsure whether something belongs in Flame Workspace, ask:

> Does this make it easier to build a normal Flame game visually while preserving Flame as the engine, Dart as the behavior language, and the Workspace semantic model as authored editor state?

If yes, it probably belongs.

If it requires Flame Workspace to become a separate engine, proprietary runtime, or opaque project format, reconsider the design.

---

# 39. Marionette Core-Component Smoke Tests

When validating editor or supported-component changes, source inspection and unit tests are not sufficient. Use the real Flame Workspace UI through Marionette in a debug desktop session.

## Required workflow

Run the narrow checks first:

1. `flutter analyze`.
2. Relevant Flutter tests.
3. Launch Flame Workspace in debug mode, for example `cd flame_workspace && flutter run -d macos` (or `-d windows` / `-d linux`).
4. Obtain the Workspace VM Service URI printed by Flutter and connect Marionette to that URI. Do not connect to the user-game preview URI by mistake and do not create a second transport.
5. Open or create a controlled fixture project.
6. Use the real Add Component dialog, including search and confirmation.
7. Edit values through the real Inspector fields and controls.
8. Inspect `workspace.getPreviewLogs`, `workspace.getDiagnostics`, and `workspace.getSyncStatus`.
9. Enter Game State with the real Play/Build/Game controls.
10. Visually inspect the preview and take a screenshot when rendering is part of the change.
11. Stop through the real toolbar.
12. Reopen or refresh the project and verify authored values remain correct.

The debug-only Workspace extensions are read-oriented diagnostics plus the narrowly scoped `workspace.selectScene` setup action. Do not use extensions to add components, edit properties, or simulate UI interactions; those operations must exercise the actual widgets.

If Marionette reports a UI failure, preview compile failure, runtime exception, disconnected VM Service, or reconciliation diagnostic, investigate and fix it before declaring the task complete. Record the failing operation, diagnostic code/message, preview logs, and recovery in the final report if it cannot be resolved.

## Mandatory component scenarios

### CircleComponent

Use a controlled fixture and perform:

```text
Add CircleComponent
radius = 40
paint color = #FF00AA
paint style = fill
position = 100, 100
Play
assert no compile error
assert no runtime sync error
take screenshot
Stop
reopen project
assert radius and color persisted
```

### TextComponent

```text
Add TextComponent
text = "Hello Flame"
color = white
font size = 32
font family = Arial
weight = bold
Play
assert no compile error
take screenshot
change text in Game State
Stop
assert Build text remains "Hello Flame"
```

This scenario must verify Build/Game isolation, not only visual output.

### TextBoxComponent

Add and exercise the real Inspector for text, text style, maximum width, margins, and content alignment. Play, inspect logs and diagnostics, screenshot the result, Stop, and verify the authored values after reopening.

### RectangleComponent and PolygonComponent

Add each component through the real dialog. Mutate its shape-specific values and Paint values in the Inspector, including transforms where supported. Play, assert compilation and runtime synchronization succeed, take a screenshot, Stop, and verify persistence after reopening.

For every scenario, use semantic component IDs and the Workspace Marionette read tools to correlate Build and Runtime state. Never treat a screenshot alone as proof that generated code, runtime reconciliation, persistence, and Build/Game isolation are correct.
