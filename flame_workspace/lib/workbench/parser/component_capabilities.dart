import 'package:flame_workspace_protocol/workspace_value.dart';

import '../project/objects/component.dart';

/// The construction contract for a discovered component.
enum ComponentCapabilityStatus { supported, partiallySupported, unsupported }

class ComponentCapability {
  const ComponentCapability({required this.status, required this.reason});

  final ComponentCapabilityStatus status;
  final String reason;

  bool get addable => status == ComponentCapabilityStatus.supported;
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
    // TextBox callbacks are behavior owned by developer code.
    'onComplete',
  };

  static bool isWorkspaceManagedParameter(String name) =>
      _ignoredConstructorParameters.contains(name);

  static ComponentCapability evaluate(FlameComponentObject component) {
    final data = component.data;
    if (data['abstract'] == true) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
        reason: 'The component is abstract and cannot be constructed.',
      );
    }
    if (data['constructorName'] is String &&
        (data['constructorName'] as String).isNotEmpty) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.unsupported,
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
        reason:
            'Required constructor parameters are unsupported: '
            '${unsupportedRequired.join(', ')}.',
      );
    }
    if (unsupportedOptional.isNotEmpty) {
      return ComponentCapability(
        status: ComponentCapabilityStatus.partiallySupported,
        reason:
            'Optional parameters are not editable: '
            '${unsupportedOptional.join(', ')}.',
      );
    }
    return const ComponentCapability(
      status: ComponentCapabilityStatus.supported,
      reason: 'All required constructor values can be generated safely.',
    );
  }
}
