import 'package:flame_workspace/workbench/model/runtime_override_store.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves scene background overrides by semantic scene ID', () {
    final store = RuntimeOverrideStore();
    store.setSceneBackgroundColor('scene:main', 0xFF123456);

    expect(
      store.resolveSceneBackgroundColor('scene:main', 0xFF000000),
      0xFF123456,
    );
    expect(
      store.resolveSceneBackgroundColor('scene:other', 0xFF000000),
      0xFF000000,
    );

    store.clear();
    expect(
      store.resolveSceneBackgroundColor('scene:main', 0xFF000000),
      0xFF000000,
    );
  });

  test('keeps property overrides isolated by semantic component ID', () {
    final store = RuntimeOverrideStore();
    store.setProperty('scene:main:component:player', 'speed', 9);
    store.setProperty('scene:main:component:enemy', 'speed', 3);
    store.setProperty('scene:main:component:player', 'label', null);

    expect(store.resolveProperty('scene:main:component:player', 'speed', 4), 9);
    expect(store.resolveProperty('scene:main:component:enemy', 'speed', 4), 3);
    expect(
      store.resolveProperty('scene:main:component:player', 'label', 'Player'),
      isNull,
    );
    expect(
      store.resolveProperty('scene:main:component:enemy', 'label', 'Enemy'),
      'Enemy',
    );
  });

  test('resolves and clears transforms and priority independently', () {
    final store = RuntimeOverrideStore();
    const authored = WorkspaceTransform(
      position: WorkspaceVector2(1, 2),
      size: WorkspaceVector2(10, 20),
      angle: 0.25,
      anchor: WorkspaceVector2(0.5, 0.5),
    );
    const runtime = WorkspaceTransform(
      position: WorkspaceVector2(3, 4),
      size: WorkspaceVector2(30, 40),
      angle: 1.5,
      anchor: WorkspaceVector2(1, 1),
    );

    store.setTransform('scene:main:component:player', runtime);
    store.setPriority('scene:main:component:player', 7);

    expect(
      store.resolveTransform('scene:main:component:player', authored),
      runtime,
    );
    expect(store.resolvePriority('scene:main:component:player', 2), 7);

    store.clear();

    expect(
      store.resolveTransform('scene:main:component:player', authored),
      authored,
    );
    expect(store.resolvePriority('scene:main:component:player', 2), 2);
  });
}
