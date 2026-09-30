import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

import '../project/objects/component.dart';
import '../project/objects/mixin.dart';
import 'type_resolver.dart';

/// A constructor parameter discovered from the installed Flame package.
class const FlameApiParameter({
  required final String name,
  required final String type,
  final String? defaultValue,
  required final bool isRequired,
  required final bool isNamed,
  required final bool isFinalField,
  required final bool isFieldFormal,
  final List<String> namedValues = const [],
}) {}

/// A constructor discovered from the installed Flame package.
class const FlameApiConstructor({
  required final String name,
  required final bool isFactory,
  required final List<FlameApiParameter> parameters,
}) {}

/// A property discovered from a Flame class or one of its ancestors.
class const FlameApiProperty({
  required final String name,
  required final String type,
  required final bool hasSetter,
  required final String declaringType,
  final bool typeAccessible = true,
  final List<String> namedValues = const [],
}) {}

/// Analyzer-independent metadata for one Flame class.
class const FlameApiClass({
  required final String name,
  required final String libraryUri,
  required final String? superType,
  required final List<String> mixins,
  required final List<String> allSupertypes,
  required final List<FlameApiConstructor> constructors,
  required final List<FlameApiProperty> properties,
  required final bool isComponent,
  required final bool isAbstract,
}) {
  bool get isPositionComponent =>
      name == 'PositionComponent' ||
      allSupertypes.contains('PositionComponent');

  Iterable<FlameApiProperty> get transformProperties => properties.where(
    (property) => _transformParameters.contains(property.name),
  );

  FlameComponentObject toComponentObject() {
    final constructor = constructors.firstWhere(
      (constructor) => constructor.name.isEmpty,
      orElse: () => constructors.isEmpty
          ? const FlameApiConstructor(
              name: '',
              isFactory: false,
              parameters: [],
            )
          : constructors.first,
    );

    final constructorFields = <FlameComponentField>[];
    final fields = <String, FlameComponentField>{};
    var positionalIndex = 0;
    for (final parameter in constructor.parameters) {
      final parameterName =
          name == 'PolygonComponent' && parameter.name == '_vertices'
          ? 'vertices'
          : parameter.name;
      final field = FlameComponentField(
        parameterName,
        (name == 'TextComponent' || name == 'TextBoxComponent') &&
                parameter.name == 'textRenderer'
            ? 'TextPaint?'
            : parameter.type,
        parameter.defaultValue,
        isPositionComponent && _transformParameters.contains(parameter.name)
            ? ['PositionComponent']
            : null,
        parameter.isFieldFormal,
        parameter.isFinalField,
        parameter.isFieldFormal && !parameter.isRequired,
        parameter.namedValues,
        parameter.isRequired,
        parameter.isNamed,
        parameter.isNamed ? null : positionalIndex++,
      );
      constructorFields.add(field);
      fields[parameter.name] = field;
    }
    for (final property in transformProperties) {
      fields.putIfAbsent(
        property.name,
        () => FlameComponentField(
          property.name,
          property.type,
          null,
          ['PositionComponent'],
          false,
          false,
          property.hasSetter,
          property.namedValues,
        ),
      );
    }

    return FlameComponentObject(
      name: name,
      type: superType ?? 'Component',
      parameters: fields.values.toList(),
      constructorParameters: constructorFields,
      writableProperties: [
        for (final property in properties)
          if (property.hasSetter &&
              (property.typeAccessible ||
                  ((name == 'TextComponent' || name == 'TextBoxComponent') &&
                      property.name == 'textRenderer')) &&
              !_transformParameters.contains(property.name))
            FlameComponentProperty(
              name: property.name,
              type:
                  (name == 'TextComponent' || name == 'TextBoxComponent') &&
                      property.name == 'textRenderer'
                  ? 'TextPaint?'
                  : property.type,
            ),
      ],
      data: {
        'source': libraryUri,
        'api': true,
        'abstract': isAbstract,
        'constructorName': constructor.name,
        'constructorIsFactory': constructor.isFactory,
        'properties': {
          for (final property in properties)
            property.name: {
              'type': property.type,
              'hasSetter': property.hasSetter,
              'declaringType': property.declaringType,
              'namedValues': property.namedValues,
            },
        },
      },
    );
  }
}

const _transformParameters = {
  'position',
  'size',
  'scale',
  'angle',
  'nativeAngle',
  'anchor',
  'children',
  'priority',
  'key',
};

/// Analyzer-independent metadata for the installed Flame package.
class FlameApiCatalog({
  required final List<FlameApiClass> classes,
  required final List<FlameMixin> mixins,
  final Set<String> accessibleTypeKeys = const {},
}) {
  final Map<String, FlameApiClass> _classesByName = {
    for (final item in classes) item.name: item,
  };

  Iterable<FlameApiClass> get componentClasses =>
      classes.where((item) => item.isComponent);

  late final List<FlameComponentObject> componentObjects = componentClasses
      .map((item) => item.toComponentObject())
      .toList();

  FlameApiClass? operator [](String name) => _classesByName[name];

  FlameApiClass? classFor(String name) => _classesByName[name];

  bool exposesType(String name, Uri libraryUri) =>
      accessibleTypeKeys.contains('$libraryUri#$name');
}

/// Discovers public Flame metadata from the package resolved for a project.
class FlameApiDiscovery {
  const FlameApiDiscovery._();

  static Future<FlameApiCatalog> resolve({
    required AnalysisContextCollection contexts,
    required String projectRoot,
    required List<TypeResolutionDiagnostic> diagnostics,
  }) async {
    final packageConfig = File(
      path.join(projectRoot, '.dart_tool', 'package_config.json'),
    );
    if (!packageConfig.existsSync()) {
      diagnostics.add(
        TypeResolutionDiagnostic(
          path: packageConfig.path,
          message: 'Cannot discover Flame APIs without package configuration.',
        ),
      );
      return FlameApiCatalog(classes: const [], mixins: const []);
    }

    try {
      final config = jsonDecode(packageConfig.readAsStringSync()) as Map;
      final packages = (config['packages'] as List).cast<Map>();
      final flame = packages.firstWhere(
        (item) => item['name'] == 'flame',
        orElse: () => <String, Object?>{},
      );
      if (flame.isEmpty) {
        diagnostics.add(
          TypeResolutionDiagnostic(
            path: packageConfig.path,
            message: 'The project does not resolve the flame package.',
          ),
        );
        return FlameApiCatalog(classes: const [], mixins: const []);
      }

      final configUri = packageConfig.uri;
      final resolvedRootUri = configUri.resolve(flame['rootUri'] as String);
      final rootUri = resolvedRootUri.path.endsWith('/')
          ? resolvedRootUri
          : resolvedRootUri.replace(path: '${resolvedRootUri.path}/');
      final libUri = rootUri.resolve(flame['packageUri'] as String);
      final libDirectory = Directory.fromUri(libUri);
      if (!libDirectory.existsSync()) {
        diagnostics.add(
          TypeResolutionDiagnostic(
            path: libDirectory.path,
            message: 'The resolved Flame package has no lib directory.',
          ),
        );
        return FlameApiCatalog(classes: const [], mixins: const []);
      }

      final session = contexts
          .contextFor(path.join(projectRoot, 'lib'))
          .currentSession;
      final libraries = <String, LibraryElement>{};
      final runtimeLibraryResult = await session.getLibraryByUri(
        'package:flame_workspace_runtime/flame_workspace_runtime.dart',
      );
      final publicNamespaces = <dynamic>[];

      if (runtimeLibraryResult is LibraryElementResult) {
        publicNamespaces.add(runtimeLibraryResult.element.exportNamespace);
      }
      final files =
          libDirectory
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => path.extension(file.path) == '.dart')
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in files) {
        final relative = path
            .relative(file.path, from: libDirectory.path)
            .replaceAll(path.separator, '/');
        final packageUri = 'package:flame/$relative';
        try {
          final libraryResult = await session.getLibraryByUri(packageUri);
          if (libraryResult is! LibraryElementResult) continue;
          final resolved = await session.getResolvedLibraryByElement(
            libraryResult.element,
          );
          if (resolved is ResolvedLibraryResult) {
            libraries[resolved.element.uri.toString()] = resolved.element;
            if (runtimeLibraryResult is! LibraryElementResult &&
                path.split(relative).length == 1) {
              publicNamespaces.add(resolved.element.exportNamespace);
            }
          }
        } on Object catch (error) {
          diagnostics.add(
            TypeResolutionDiagnostic(
              path: packageUri,
              message: 'Flame library could not be resolved: $error',
            ),
          );
        }
      }

      return _catalogFromLibraries(libraries.values, publicNamespaces);
    } on Object catch (error) {
      diagnostics.add(
        TypeResolutionDiagnostic(
          path: packageConfig.path,
          message: 'Flame API discovery failed: $error',
        ),
      );
      return FlameApiCatalog(classes: const [], mixins: const []);
    }
  }

  static FlameApiCatalog _catalogFromLibraries(
    Iterable<LibraryElement> libraries,
    List<dynamic> publicNamespaces,
  ) {
    final classes = <ClassElement>[];
    final mixins = <MixinElement>[];
    final seenClasses = <String>{};
    final seenMixins = <String>{};

    for (final library in libraries) {
      for (final element in library.classes) {
        final name = element.name;
        if (name == null || name.startsWith('_')) continue;
        if (!_isPubliclyExported(name, element.library.uri, publicNamespaces)) {
          continue;
        }
        final key = '${library.uri}#$name';
        if (seenClasses.add(key)) classes.add(element);
      }
      for (final element in library.mixins) {
        final name = element.name;
        if (name == null || name.startsWith('_')) continue;
        if (!_isPubliclyExported(name, element.library.uri, publicNamespaces)) {
          continue;
        }
        final key = '${library.uri}#$name';
        if (seenMixins.add(key)) mixins.add(element);
      }
    }

    final classMetadata =
        classes
            .map((element) => _classMetadata(element, publicNamespaces))
            .where((item) => item != null)
            .cast<FlameApiClass>()
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final mixinMetadata = mixins.map(_mixinMetadata).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final accessibleTypeKeys = <String>{};
    for (final namespace in publicNamespaces) {
      for (final element in namespace.definedNames2.values) {
        if (element is Element &&
            element.name != null &&
            element.library != null) {
          accessibleTypeKeys.add('${element.library!.uri}#${element.name}');
        }
      }
    }
    return FlameApiCatalog(
      classes: classMetadata,
      mixins: mixinMetadata,
      accessibleTypeKeys: accessibleTypeKeys,
    );
  }

  static bool _isPubliclyExported(
    String name,
    Uri libraryUri,
    List<dynamic> namespaces,
  ) {
    return namespaces.any((namespace) {
      final element = namespace.get2(name);

      return element is Element &&
          element.name == name &&
          element.library?.uri == libraryUri &&
          !element.isPrivate;
    });
  }

  static FlameApiClass? _classMetadata(
    ClassElement element,
    List<dynamic> publicNamespaces,
  ) {
    final name = element.name;
    if (name == null) return null;

    final superType = element.supertype;
    final allSupertypes = element.allSupertypes
        .map((type) => type.element.name)
        .whereType<String>()
        .toList();
    final isComponent =
        name == 'Component' || allSupertypes.contains('Component');

    final properties = <FlameApiProperty>[];
    final propertiesByName = <String, FlameApiProperty>{};
    void addProperties(Iterable<Element> members) {
      for (final member in members) {
        if (member is! GetterElement || member.isStatic) continue;
        final memberName = member.displayName;
        if (memberName.isEmpty || memberName.startsWith('_')) continue;
        final enclosing = member.enclosingElement;
        final setter = member.correspondingSetter;
        propertiesByName.putIfAbsent(
          memberName,
          () => FlameApiProperty(
            name: memberName,
            type:
                setter?.formalParameters.firstOrNull?.type.getDisplayString() ??
                member.returnType.getDisplayString(),
            hasSetter: setter != null,
            declaringType: enclosing is InterfaceElement
                ? enclosing.name ?? name
                : name,
            typeAccessible:
                setter == null ||
                _isTypeAccessible(
                  setter.formalParameters.firstOrNull!.type,
                  publicNamespaces,
                ),
            namedValues: _namedValues(member.returnType),
          ),
        );
      }
    }

    addProperties(element.interfaceMembers.values);
    addProperties(element.inheritedMembers.values);
    properties.addAll(propertiesByName.values);
    properties.sort((a, b) => a.name.compareTo(b.name));

    return FlameApiClass(
      name: name,
      libraryUri: element.library.uri.toString(),
      superType: superType?.element.name,
      mixins: element.mixins
          .map((mixin) => mixin.element.name)
          .whereType<String>()
          .toList(),
      allSupertypes: allSupertypes,
      constructors: element.constructors.map(_constructorMetadata).toList(),
      properties: properties,
      isComponent: isComponent,
      isAbstract: element.isAbstract,
    );
  }

  static bool _isTypeAccessible(DartType type, List<dynamic> namespaces) {
    if (type is FunctionType || type is TypeParameterType) return false;
    final typeElement = type.element;

    if (typeElement is InterfaceElement &&
        !typeElement.library.isDartCore &&
        !_isPubliclyExported(
          typeElement.name ?? '',
          typeElement.library.uri,
          namespaces,
        )) {
      return false;
    }
    return type is! InterfaceType ||
        type.typeArguments.every(
          (argument) => _isTypeAccessible(argument, namespaces),
        );
  }

  static FlameApiConstructor _constructorMetadata(ConstructorElement element) {
    return FlameApiConstructor(
      name: element.name == 'new' ? '' : element.name ?? '',
      isFactory: element.isFactory,
      parameters: element.formalParameters
          .map(
            (parameter) => FlameApiParameter(
              name: parameter.name ?? '',
              type: parameter.type.getDisplayString(),
              defaultValue: parameter.defaultValueCode,
              isRequired: parameter.isRequired,
              isNamed: parameter.isNamed,
              isFinalField:
                  parameter is FieldFormalParameterElement &&
                  (parameter.field?.isFinal ?? false),
              isFieldFormal: parameter is FieldFormalParameterElement,
              namedValues: _namedValues(parameter.type),
            ),
          )
          .toList(),
    );
  }

  static List<String> _namedValues(DartType type) {
    final element = type.element;
    if (element is! InterfaceElement) return const [];
    return element.fields
        .where((field) => field.isStatic && field.isConst)
        .map((field) => field.name)
        .whereType<String>()
        .toList();
  }

  static FlameMixin _mixinMetadata(MixinElement element) {
    final name = element.name ?? '';
    final constraints = element.superclassConstraints
        .map((type) => type.getDisplayString())
        .where((type) => type != 'Object')
        .toList();
    final types = element.typeParameters
        .where((parameter) => parameter.name != null)
        .map(
          (parameter) => (parameter.name!, parameter.bound?.getDisplayString()),
        )
        .toList();

    return FlameMixin(
      name: name,
      types: types,
      isComponentRestricted: constraints.any(
        (constraint) => constraint == 'Component',
      ),
      isSceneRestricted: constraints.any(
        (constraint) =>
            constraint == 'World' || constraint.contains('FlameGame'),
      ),
      on: constraints,
    );
  }
}
