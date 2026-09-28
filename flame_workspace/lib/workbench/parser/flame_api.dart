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
class FlameApiParameter {
  final String name;
  final String type;
  final String? defaultValue;
  final bool isRequired;
  final bool isNamed;
  final bool isFinalField;
  final bool isFieldFormal;
  final List<String> namedValues;

  const FlameApiParameter({
    required this.name,
    required this.type,
    this.defaultValue,
    required this.isRequired,
    required this.isNamed,
    required this.isFinalField,
    required this.isFieldFormal,
    this.namedValues = const [],
  });
}

/// A constructor discovered from the installed Flame package.
class FlameApiConstructor {
  final String name;
  final bool isFactory;
  final List<FlameApiParameter> parameters;

  const FlameApiConstructor({
    required this.name,
    required this.isFactory,
    required this.parameters,
  });
}

/// A property discovered from a Flame class or one of its ancestors.
class FlameApiProperty {
  final String name;
  final String type;
  final bool hasSetter;
  final String declaringType;
  final List<String> namedValues;

  const FlameApiProperty({
    required this.name,
    required this.type,
    required this.hasSetter,
    required this.declaringType,
    this.namedValues = const [],
  });
}

/// Analyzer-independent metadata for one Flame class.
class FlameApiClass {
  final String name;
  final String libraryUri;
  final String? superType;
  final List<String> mixins;
  final List<String> allSupertypes;
  final List<FlameApiConstructor> constructors;
  final List<FlameApiProperty> properties;
  final bool isComponent;

  const FlameApiClass({
    required this.name,
    required this.libraryUri,
    required this.superType,
    required this.mixins,
    required this.allSupertypes,
    required this.constructors,
    required this.properties,
    required this.isComponent,
  });

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

    final fields = <String, FlameComponentField>{};
    for (final parameter in constructor.parameters) {
      fields[parameter.name] = FlameComponentField(
        parameter.name,
        parameter.type,
        parameter.defaultValue,
        isPositionComponent && _transformParameters.contains(parameter.name)
            ? ['PositionComponent']
            : null,
        parameter.isFieldFormal,
        parameter.isFinalField,
        parameter.isFieldFormal && !parameter.isRequired,
        parameter.namedValues,
      );
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
      data: {
        'source': libraryUri,
        'api': true,
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
class FlameApiCatalog {
  final List<FlameApiClass> classes;
  final List<FlameMixin> mixins;
  final Map<String, FlameApiClass> _classesByName;

  FlameApiCatalog({required this.classes, required this.mixins})
    : _classesByName = {for (final item in classes) item.name: item};

  Iterable<FlameApiClass> get componentClasses =>
      classes.where((item) => item.isComponent);

  late final List<FlameComponentObject> componentObjects = componentClasses
      .map((item) => item.toComponentObject())
      .toList();

  FlameApiClass? operator [](String name) => _classesByName[name];

  FlameApiClass? classFor(String name) => _classesByName[name];
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

      return _catalogFromLibraries(libraries.values);
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
  ) {
    final classes = <ClassElement>[];
    final mixins = <MixinElement>[];
    final seenClasses = <String>{};
    final seenMixins = <String>{};

    for (final library in libraries) {
      for (final element in library.classes) {
        final key = '${library.uri}#${element.name}';
        if (seenClasses.add(key)) classes.add(element);
      }
      for (final element in library.mixins) {
        final key = '${library.uri}#${element.name}';
        if (seenMixins.add(key)) mixins.add(element);
      }
    }

    final classMetadata =
        classes
            .map(_classMetadata)
            .where((item) => item != null)
            .cast<FlameApiClass>()
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final mixinMetadata = mixins.map(_mixinMetadata).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return FlameApiCatalog(classes: classMetadata, mixins: mixinMetadata);
  }

  static FlameApiClass? _classMetadata(ClassElement element) {
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
        propertiesByName.putIfAbsent(
          memberName,
          () => FlameApiProperty(
            name: memberName,
            type: member.returnType.getDisplayString(),
            hasSetter: member.correspondingSetter != null,
            declaringType: enclosing is InterfaceElement
                ? enclosing.name ?? name
                : name,
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
