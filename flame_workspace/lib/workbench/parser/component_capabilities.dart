import 'dart:convert';

import 'package:flame_workspace_protocol/workspace_value.dart';

import '../project/objects/component.dart';

/// The construction contract for a discovered component.
enum ComponentCapabilityStatus { supported, partiallySupported, unsupported }

enum ComponentSupportTier { coreVisual, tier2, unsupported }

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
    this.defaultProperties = const {},
  });

  final String name;
  final ComponentSupportTier tier;
  final Map<String, Object?> defaultProperties;
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

  static const coreVisual = <ComponentSupportSpec>[
    ComponentSupportSpec(
      name: 'PositionComponent',
      tier: ComponentSupportTier.coreVisual,
    ),
    ComponentSupportSpec(
      name: 'SpriteComponent',
      tier: ComponentSupportTier.coreVisual,
    ),
    ComponentSupportSpec(
      name: 'CircleComponent',
      tier: ComponentSupportTier.coreVisual,
      defaultProperties: {'radius': 32.0},
    ),
    ComponentSupportSpec(
      name: 'RectangleComponent',
      tier: ComponentSupportTier.coreVisual,
      defaultProperties: {
        'paint': WorkspacePaint(color: WorkspaceColor(0xFF4CAF50)),
      },
    ),
    ComponentSupportSpec(
      name: 'PolygonComponent',
      tier: ComponentSupportTier.coreVisual,
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
      defaultProperties: {
        'text': 'Core Visual',
        'textRenderer': WorkspaceTextPaint(),
      },
    ),
    ComponentSupportSpec(
      name: 'TextBoxComponent',
      tier: ComponentSupportTier.coreVisual,
      defaultProperties: {
        'text': 'Core Visual',
        'textRenderer': WorkspaceTextPaint(),
        'boxConfig': WorkspaceTextBoxConfig(),
        'align': WorkspaceAnchor(0, 0),
      },
    ),
  ];

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
  });

  final ComponentCapabilityStatus status;
  final String reason;
  final ComponentSupportTier tier;
  final ComponentSupportGroup group;

  bool get addable =>
      status == ComponentCapabilityStatus.supported &&
      (group == ComponentSupportGroup.coreSupported ||
          group == ComponentSupportGroup.supportedGenerically);
}

class ComponentSupportReportEntry {
  const ComponentSupportReportEntry({
    required this.name,
    required this.type,
    required this.group,
    required this.status,
    required this.tier,
    required this.addable,
    required this.reason,
  });

  final String name;
  final String type;
  final ComponentSupportGroup group;
  final ComponentCapabilityStatus status;
  final ComponentSupportTier tier;
  final bool addable;
  final String reason;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    'group': group.jsonName,
    'status': status.name,
    'tier': tier.name,
    'addable': addable,
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
      addable: capability.addable,
      reason: capability.reason,
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
    if (tier == ComponentSupportTier.tier2) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        group: ComponentSupportGroup.specializedEditorRequired,
        reason: 'This component is planned for Tier 2 and is not addable yet.',
      );
    }
    if (data['api'] == true && tier == ComponentSupportTier.unsupported) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        tier: tier,
        group: ComponentSupportGroup.specializedEditorRequired,
        reason:
            'Flame Workspace has no component-specific construction and '
            'property contract for this Flame API yet.',
      );
    }
    if (data['abstract'] == true) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
        tier: tier,
        group: ComponentSupportGroup.unsupported,
        reason: 'The component is abstract and cannot be constructed.',
      );
    }
    if (data['constructorName'] is String &&
        (data['constructorName'] as String).isNotEmpty) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
        tier: tier,
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
        group: ComponentSupportGroup.specializedEditorRequired,
        reason:
            'Optional parameters are not editable: '
            '${unsupportedOptional.join(', ')}.',
      );
    }
    return ComponentCapability(
      status: ComponentCapabilityStatus.supported,
      tier: tier,
      group: tier == ComponentSupportTier.coreVisual
          ? ComponentSupportGroup.coreSupported
          : ComponentSupportGroup.supportedGenerically,
      reason: 'All required constructor values can be generated safely.',
    );
  }
}
