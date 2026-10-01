import 'dart:convert';

import 'package:flame_workspace_protocol/workspace_value.dart';

import '../project/objects/component.dart';

/// The construction contract for a discovered component.
enum ComponentCapabilityStatus { supported, partiallySupported, unsupported }

enum ComponentSupportTier { coreVisual, tier2, unsupported }

enum ComponentSupportKind {
  visualSceneComponent,
  nonvisualSceneComponent,
  sceneInfrastructure,
  developerBehavior,
}

enum ComponentSupportCategory {
  foundational,
  basicVisual,
  intermediateVisual,
  uiInput,
  utility,
  sceneInfrastructure,
  specializedEditorRequired,
  unsupported,
}

extension ComponentSupportCategoryName on ComponentSupportCategory {
  String get jsonName => switch (this) {
    ComponentSupportCategory.foundational => 'Foundational',
    ComponentSupportCategory.basicVisual => 'Basic visual',
    ComponentSupportCategory.intermediateVisual => 'Intermediate visual',
    ComponentSupportCategory.uiInput => 'UI / input',
    ComponentSupportCategory.utility => 'Utility / nonvisual',
    ComponentSupportCategory.sceneInfrastructure => 'Scene infrastructure',
    ComponentSupportCategory.specializedEditorRequired =>
      'Specialized editor required',
    ComponentSupportCategory.unsupported => 'Unsupported',
  };
}

enum ComponentSupportGroup {
  coreSupported,
  supportedGenerically,
  specializedEditorRequired,
  notAppropriateForVisualConstruction,
  unsupported,
}

extension ComponentSupportGroupName on ComponentSupportGroup {
  String get jsonName => switch (this) {
    ComponentSupportGroup.coreSupported => 'Core supported',
    ComponentSupportGroup.supportedGenerically => 'Supported generically',
    ComponentSupportGroup.specializedEditorRequired =>
      'Specialized editor required',
    ComponentSupportGroup.notAppropriateForVisualConstruction =>
      'Not appropriate for visual construction',
    ComponentSupportGroup.unsupported => 'Unsupported',
  };
}

class ComponentSupportSpec {
  const ComponentSupportSpec({
    required this.name,
    required this.tier,
    required this.category,
    required this.kind,
    this.defaultProperties = const {},
    this.addable = false,
    this.container = false,
    this.transformable = false,
    this.sceneRenderer = false,
    this.assetBacked = false,
    this.specializedConstructorEditor = false,
    this.runtimeMutation = false,
    this.runtimeRecreation = false,
    this.deferredReason,
  });

  final String name;
  final ComponentSupportTier tier;
  final ComponentSupportCategory category;
  final ComponentSupportKind kind;
  final Map<String, Object?> defaultProperties;
  final bool addable;
  final bool container;
  final bool transformable;
  final bool sceneRenderer;
  final bool assetBacked;
  final bool specializedConstructorEditor;
  final bool runtimeMutation;
  final bool runtimeRecreation;
  final String? deferredReason;
}

/// The explicit Developer Preview component support matrix.
///
/// Discovery remains dynamic; this matrix describes the workflows Workspace
/// intentionally promises to support. Components outside the matrix must not
/// be treated as Core Visual Components merely because Analyzer discovers them.
class ComponentSupportMatrix {
  const ComponentSupportMatrix._();

  static const _coreInspectorProperties = <String, Set<String>>{
    'PositionComponent': {},
    'SpriteComponent': {},
    'CircleComponent': {'radius', 'paint'},
    'RectangleComponent': {'paint'},
    'PolygonComponent': {'vertices', 'paint'},
    'TextComponent': {'text', 'textRenderer'},
    'TextBoxComponent': {'text', 'textRenderer', 'boxConfig', 'align'},
  };

  /// Whether an ordinary Inspector field is part of the Core Visual contract.
  ///
  /// Discovered setters remain available as API metadata, but are not thereby
  /// promised to have a supported semantic value/editor/runtime path.
  static bool exposesInspectorProperty(String component, String property) {
    final supported = _coreInspectorProperties[component];
    return supported == null || supported.contains(property);
  }

  static bool supportsRuntimeProperty(String component, String property) =>
      _coreInspectorProperties[component]?.contains(property) ?? false;

  static const coreVisual = <ComponentSupportSpec>[
    ComponentSupportSpec(
      name: 'PositionComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.foundational,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      container: true,
      transformable: true,
      sceneRenderer: true,
      runtimeMutation: true,
    ),
    ComponentSupportSpec(
      name: 'SpriteComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.basicVisual,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      transformable: true,
      sceneRenderer: true,
      assetBacked: true,
      runtimeMutation: true,
    ),
    ComponentSupportSpec(
      name: 'CircleComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.basicVisual,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      transformable: true,
      sceneRenderer: true,
      runtimeMutation: true,
      defaultProperties: {'radius': 32.0},
    ),
    ComponentSupportSpec(
      name: 'RectangleComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.basicVisual,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      transformable: true,
      sceneRenderer: true,
      runtimeMutation: true,
      defaultProperties: {
        'paint': WorkspacePaint(color: WorkspaceColor(0xFF4CAF50)),
      },
    ),
    ComponentSupportSpec(
      name: 'PolygonComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.basicVisual,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      transformable: true,
      sceneRenderer: true,
      runtimeMutation: true,
      defaultProperties: {
        'vertices': [
          WorkspaceVectorValue(0, 0),
          WorkspaceVectorValue(64, 0),
          WorkspaceVectorValue(32, 48),
        ],
        'paint': WorkspacePaint(color: WorkspaceColor(0xFF2196F3)),
      },
    ),
    ComponentSupportSpec(
      name: 'TextComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.basicVisual,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      transformable: true,
      sceneRenderer: true,
      runtimeMutation: true,
      defaultProperties: {
        'text': 'Core Visual',
        'textRenderer': WorkspaceTextPaint(),
      },
    ),
    ComponentSupportSpec(
      name: 'TextBoxComponent',
      tier: ComponentSupportTier.coreVisual,
      category: ComponentSupportCategory.basicVisual,
      kind: ComponentSupportKind.visualSceneComponent,
      addable: true,
      transformable: true,
      sceneRenderer: true,
      runtimeMutation: true,
      defaultProperties: {
        'text': 'Core Visual',
        'textRenderer': WorkspaceTextPaint(),
        'boxConfig': WorkspaceTextBoxConfig(),
        'align': WorkspaceAnchor(0, 0),
      },
    ),
  ];

  static const _catalog = <String, ComponentSupportCategory>{
    'Component': ComponentSupportCategory.foundational,
    'EllipseComponent': ComponentSupportCategory.basicVisual,
    'IconComponent': ComponentSupportCategory.basicVisual,
    'SpriteAnimationComponent': ComponentSupportCategory.intermediateVisual,
    'NineTileBoxComponent': ComponentSupportCategory.intermediateVisual,
    'ClipComponent': ComponentSupportCategory.intermediateVisual,
    'ParallaxComponent': ComponentSupportCategory.intermediateVisual,
    'SpriteGroupComponent': ComponentSupportCategory.intermediateVisual,
    'SpriteAnimationGroupComponent':
        ComponentSupportCategory.intermediateVisual,
    'ButtonComponent': ComponentSupportCategory.uiInput,
    'SpriteButtonComponent': ComponentSupportCategory.uiInput,
    'HudButtonComponent': ComponentSupportCategory.uiInput,
    'JoystickComponent': ComponentSupportCategory.uiInput,
    'HudMarginComponent': ComponentSupportCategory.uiInput,
    'TimerComponent': ComponentSupportCategory.utility,
    'World': ComponentSupportCategory.sceneInfrastructure,
    'CameraComponent': ComponentSupportCategory.sceneInfrastructure,
    'Viewport': ComponentSupportCategory.sceneInfrastructure,
    'Viewfinder': ComponentSupportCategory.sceneInfrastructure,
    'ParticleComponent': ComponentSupportCategory.specializedEditorRequired,
    'SpriteBatchComponent': ComponentSupportCategory.specializedEditorRequired,
    'SpawnComponent': ComponentSupportCategory.specializedEditorRequired,
    'IsometricTileMapComponent':
        ComponentSupportCategory.specializedEditorRequired,
    'CustomPainterComponent':
        ComponentSupportCategory.specializedEditorRequired,
    'RouterComponent': ComponentSupportCategory.specializedEditorRequired,
  };

  static ComponentSupportSpec? specFor(String name) {
    for (final spec in coreVisual) {
      if (spec.name == name) return spec;
    }
    final category = _catalog[name];
    if (category == null) return null;
    return ComponentSupportSpec(
      name: name,
      tier: category == ComponentSupportCategory.intermediateVisual
          ? ComponentSupportTier.tier2
          : ComponentSupportTier.unsupported,
      category: category,
      kind: switch (category) {
        ComponentSupportCategory.sceneInfrastructure =>
          ComponentSupportKind.sceneInfrastructure,
        ComponentSupportCategory.utility =>
          ComponentSupportKind.nonvisualSceneComponent,
        ComponentSupportCategory.uiInput ||
        ComponentSupportCategory.specializedEditorRequired =>
          ComponentSupportKind.developerBehavior,
        _ => ComponentSupportKind.visualSceneComponent,
      },
      specializedConstructorEditor:
          category == ComponentSupportCategory.specializedEditorRequired,
      container: category == ComponentSupportCategory.sceneInfrastructure,
      deferredReason: _deferredReason[name],
    );
  }

  static const _deferredReason = <String, String>{
    // A Workspace scene is already the authored World composition. A nested
    // World would create a second ownership boundary without a safe editor use.
    'World': 'Workspace scenes own the authored World and do not add nested World components.',
    'CameraComponent': 'Camera configuration belongs to scene/game infrastructure, not the visual child palette.',
    'Viewport': 'Viewport configuration belongs to the CameraComponent infrastructure contract.',
    'Viewfinder': 'Viewfinder configuration belongs to the CameraComponent infrastructure contract.',
    'TimerComponent': 'Timer callbacks are developer behavior and are not authored as scene data.',
    'SpriteGroupComponent': 'Requires a finite, resolved generic state type and state-to-sprite map.',
    'SpriteAnimationGroupComponent': 'Requires a finite, resolved generic state type and state-to-animation map.',
    'SpriteButtonComponent': 'Visual sprites are representable, but callback behavior remains developer-owned.',
    'ButtonComponent': 'Visual states require canonical component references; callbacks remain developer-owned.',
    'HudButtonComponent': 'HUD visual states require canonical component references; callbacks remain developer-owned.',
    'JoystickComponent': 'Knob/background are PositionComponent objects and need semantic references or owned children.',
    'HudMarginComponent': 'HUD layout requires a semantic margin and descendant composition editor.',
  };

  static ComponentSupportCategory categoryFor(String name) =>
      specFor(name)?.category ?? ComponentSupportCategory.unsupported;

  static const _tier2 = {
    'SpriteAnimationComponent': ComponentSupportTier.tier2,
  };

  static ComponentSupportTier tierFor(String name) {
    if (coreVisual.any((spec) => spec.name == name)) {
      return ComponentSupportTier.coreVisual;
    }
    return _tier2[name] ?? ComponentSupportTier.unsupported;
  }
}

class ComponentCapability {
  const ComponentCapability({
    required this.status,
    required this.reason,
    this.tier = ComponentSupportTier.unsupported,
    this.group = ComponentSupportGroup.unsupported,
    this.category = ComponentSupportCategory.unsupported,
    this.kind = ComponentSupportKind.visualSceneComponent,
    this.addableOverride,
    this.container = false,
    this.transformable = false,
    this.sceneRenderer = false,
    this.assetBacked = false,
    this.specializedConstructorEditor = false,
    this.runtimeMutation = false,
    this.runtimeRecreation = false,
  });

  final ComponentCapabilityStatus status;
  final String reason;
  final ComponentSupportTier tier;
  final ComponentSupportGroup group;
  final ComponentSupportCategory category;
  final ComponentSupportKind kind;
  final bool? addableOverride;
  final bool container;
  final bool transformable;
  final bool sceneRenderer;
  final bool assetBacked;
  final bool specializedConstructorEditor;
  final bool runtimeMutation;
  final bool runtimeRecreation;

  bool get addable =>
      addableOverride ??
      (status == ComponentCapabilityStatus.supported &&
          (group == ComponentSupportGroup.coreSupported ||
              group == ComponentSupportGroup.supportedGenerically));
}

class ComponentSupportReportEntry {
  const ComponentSupportReportEntry({
    required this.name,
    required this.type,
    required this.group,
    required this.status,
    required this.tier,
    required this.category,
    required this.kind,
    required this.addable,
    required this.reason,
    required this.container,
    required this.transformable,
    required this.sceneRenderer,
    required this.assetBacked,
    required this.specializedConstructorEditor,
    required this.runtimeMutation,
    required this.runtimeRecreation,
  });

  final String name;
  final String type;
  final ComponentSupportGroup group;
  final ComponentCapabilityStatus status;
  final ComponentSupportTier tier;
  final ComponentSupportCategory category;
  final ComponentSupportKind kind;
  final bool addable;
  final String reason;
  final bool container;
  final bool transformable;
  final bool sceneRenderer;
  final bool assetBacked;
  final bool specializedConstructorEditor;
  final bool runtimeMutation;
  final bool runtimeRecreation;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    'group': group.jsonName,
    'status': status.name,
    'tier': tier.name,
    'category': category.jsonName,
    'kind': kind.name,
    'addable': addable,
    'capabilities': {
      'container': container,
      'transformable': transformable,
      'sceneRenderer': sceneRenderer,
      'assetBacked': assetBacked,
      'specializedConstructorEditor': specializedConstructorEditor,
      'runtimeMutation': runtimeMutation,
      'runtimeRecreation': runtimeRecreation,
    },
    'reason': reason,
  };
}

/// Deterministic, machine-readable support information for the discovered
/// Flame component catalog. The Add Component UI uses the same evaluator that
/// produces each entry, so the report cannot drift from addability decisions.
class ComponentSupportReport {
  const ComponentSupportReport(this.entries);

  final List<ComponentSupportReportEntry> entries;

  factory ComponentSupportReport.fromCatalog(
    Iterable<FlameComponentObject> catalog,
  ) {
    final entries = [for (final component in catalog) _entryFor(component)]
      ..sort((a, b) => a.name.compareTo(b.name));
    return ComponentSupportReport(List.unmodifiable(entries));
  }

  Map<String, Object?> toJson() {
    final groups = <String, List<Map<String, Object?>>>{
      for (final group in ComponentSupportGroup.values) group.jsonName: [],
    };
    for (final entry in entries) {
      groups[entry.group.jsonName]!.add(entry.toJson());
    }
    return {
      'schemaVersion': 1,
      'groups': groups,
      'components': [for (final entry in entries) entry.toJson()],
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static ComponentSupportReportEntry _entryFor(FlameComponentObject component) {
    final capability = ComponentCapabilityEvaluator.evaluate(component);
    return ComponentSupportReportEntry(
      name: component.name,
      type: component.type,
      group: capability.group,
      status: capability.status,
      tier: capability.tier,
      category: capability.category,
      kind: capability.kind,
      addable: capability.addable,
      reason: capability.reason,
      container: capability.container,
      transformable: capability.transformable,
      sceneRenderer: capability.sceneRenderer,
      assetBacked: capability.assetBacked,
      specializedConstructorEditor: capability.specializedConstructorEditor,
      runtimeMutation: capability.runtimeMutation,
      runtimeRecreation: capability.runtimeRecreation,
    );
  }
}

/// Evaluates whether discovered metadata can safely cross the Add Component
/// and generated-source boundary.
class ComponentCapabilityEvaluator {
  const ComponentCapabilityEvaluator._();

  static const _ignoredConstructorParameters = {
    'children',
    'key',
    'position',
    'size',
    'scale',
    'angle',
    'nativeAngle',
    'anchor',
    'priority',
    // Flame's shape components expose this optional rendering optimization;
    // Workspace uses the public `paint` value instead.
    'paintLayers',
    // Sprite assets are represented by ComponentInstance.assetPath.
    'sprite',
    // TextBox callbacks are behavior owned by developer code.
    'onComplete',
  };

  static bool isWorkspaceManagedParameter(String name) =>
      _ignoredConstructorParameters.contains(name);

  static ComponentCapability evaluate(FlameComponentObject component) {
    final data = component.data;
    final tier = ComponentSupportMatrix.tierFor(component.name);
    final spec = ComponentSupportMatrix.specFor(component.name);
    final category = spec?.category ?? ComponentSupportCategory.unsupported;
    if (category == ComponentSupportCategory.sceneInfrastructure) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        category: category,
        kind: ComponentSupportKind.sceneInfrastructure,
        group: ComponentSupportGroup.notAppropriateForVisualConstruction,
        addableOverride: false,
        container: true,
        reason: 'This is scene infrastructure and is not an ordinary addable component.',
      );
    }
    if (category == ComponentSupportCategory.specializedEditorRequired ||
        category == ComponentSupportCategory.uiInput) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        category: category,
        kind: spec?.kind ?? ComponentSupportKind.developerBehavior,
        group: ComponentSupportGroup.specializedEditorRequired,
        addableOverride: false,
        specializedConstructorEditor: true,
        reason: spec?.deferredReason ?? 'This component requires a specialized editor and is not addable yet.',
      );
    }
    if (tier == ComponentSupportTier.tier2) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        category: category,
        group: ComponentSupportGroup.specializedEditorRequired,
        addableOverride: false,
        specializedConstructorEditor: true,
        reason: 'This component is planned for Tier 2 and is not addable yet.',
      );
    }
    if (data['api'] == true && tier == ComponentSupportTier.unsupported) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        category: category,
        kind: spec?.kind ?? ComponentSupportKind.developerBehavior,
        group: ComponentSupportGroup.specializedEditorRequired,
        addableOverride: false,
        specializedConstructorEditor: true,
        reason:
            'Flame Workspace has no component-specific construction and '
            'property contract for this Flame API yet.',
      );
    }
    if (data['abstract'] == true) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
        tier: tier,
        category: category,
        group: ComponentSupportGroup.unsupported,
        reason: 'The component is abstract and cannot be constructed.',
      );
    }
    if (data['constructorName'] is String &&
        (data['constructorName'] as String).isNotEmpty) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
        tier: tier,
        category: category,
        group: ComponentSupportGroup.specializedEditorRequired,
        reason: 'Workspace supports the unnamed constructor only.',
      );
    }

    final unsupportedRequired = <String>[];
    final unsupportedOptional = <String>[];
    for (final parameter
        in component.constructorParameters ?? component.parameters) {
      if (_ignoredConstructorParameters.contains(parameter.name)) continue;
      final adapter = PropertyTypeAdapterRegistry.adapterFor(
        parameter.type,
        enumValues: parameter.enumValues,
      );
      final supported =
          adapter.editorKind != WorkspacePropertyEditorKind.unsupported &&
          adapter.supports(parameter.type, enumValues: parameter.enumValues);
      if (supported) continue;
      if (parameter.isRequired && parameter.defaultValue == null) {
        unsupportedRequired.add('${parameter.name} (${parameter.type})');
      } else {
        unsupportedOptional.add('${parameter.name} (${parameter.type})');
      }
    }

    if (unsupportedRequired.isNotEmpty) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
        tier: tier,
        category: category,
        group: ComponentSupportGroup.unsupported,
        reason:
            'Required constructor parameters are unsupported: '
            '${unsupportedRequired.join(', ')}.',
      );
    }
    if (unsupportedOptional.isNotEmpty) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        category: category,
        group: ComponentSupportGroup.specializedEditorRequired,
        reason:
            'Optional parameters are not editable: '
            '${unsupportedOptional.join(', ')}.',
      );
    }
    return ComponentCapability(
      status: ComponentCapabilityStatus.supported,
      tier: tier,
      category: category,
      group: tier == ComponentSupportTier.coreVisual
          ? ComponentSupportGroup.coreSupported
          : ComponentSupportGroup.supportedGenerically,
      addableOverride: spec?.addable,
      container: spec?.container ?? false,
      transformable: spec?.transformable ?? false,
      sceneRenderer: spec?.sceneRenderer ?? false,
      assetBacked: spec?.assetBacked ?? false,
      specializedConstructorEditor: spec?.specializedConstructorEditor ?? false,
      runtimeMutation: spec?.runtimeMutation ?? false,
      runtimeRecreation: spec?.runtimeRecreation ?? false,
      kind: spec?.kind ?? ComponentSupportKind.visualSceneComponent,
      reason: 'All required constructor values can be generated safely.',
    );
  }
}
