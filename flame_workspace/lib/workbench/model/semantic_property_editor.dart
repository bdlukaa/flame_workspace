import 'package:flame_workspace_protocol/workspace_value.dart';

import 'semantic_model.dart';

class const SemanticPropertyEdit({
  required final Object? modelValue,
  required final Object? runtimeValue,
}) {}

/// Compatibility facade over the protocol package's UI-neutral type registry.
class SemanticPropertyEditor {
  const SemanticPropertyEditor._();

  static List<String> get anchorValues => WorkspaceValueCodec.anchorOptions;

  static WorkspacePropertyTypeMetadata metadata(
    WorkspacePropertyDefinition definition,
  ) => PropertyTypeAdapterRegistry.metadata(
    definition.type,
    enumValues: definition.enumValues,
  );

  static WorkspacePropertyEditorKind kindFor(
    WorkspacePropertyDefinition definition,
  ) => metadata(definition).editorKind;

  static List<String> optionsFor(WorkspacePropertyDefinition definition) =>
      metadata(definition).options;

  static SemanticPropertyEdit? parse(
    WorkspacePropertyDefinition definition,
    String rawValue,
  ) {
    final typeMetadata = metadata(definition);
    try {
      final modelValue = typeMetadata.adapter.parse(
        definition.type,
        rawValue,
        enumValues: definition.enumValues,
      );
      return SemanticPropertyEdit(
        modelValue: modelValue,
        runtimeValue: typeMetadata.adapter.encodeRuntime(
          definition.type,
          modelValue,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  static String displayValue(
    WorkspacePropertyDefinition definition,
    Object? value,
  ) => metadata(definition).adapter.display(value);

  static String? optionFromValue(Object? value) =>
      WorkspaceValueCodec.optionValue(value);

  static WorkspaceVector2? vectorFromValue(Object? value) {
    if (value is WorkspaceVectorValue) {
      return WorkspaceVector2(value.x, value.y);
    }
    if (value is WorkspaceVector2) return value;
    return null;
  }

  static WorkspaceVector2 anchorVector(String value) {
    try {
      final anchor = PropertyTypeAdapterRegistry.parse('Anchor', value);
      if (anchor is WorkspaceAnchor) {
        return WorkspaceVector2(anchor.x, anchor.y);
      }
    } on FormatException {
      // Invalid UI choices fall back to a neutral anchor.
    }
    return const WorkspaceVector2.zero();
  }
}
