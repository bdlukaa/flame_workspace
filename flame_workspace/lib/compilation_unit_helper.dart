import 'package:analyzer/dart/ast/ast.dart';
import 'package:flame_workspace/utils.dart';

typedef IndexedUnit = Map<String, dynamic>;

class CompilationUnitHelper {
  final CompilationUnit unit;
  final IndexedUnit indexed;

  const CompilationUnitHelper({required this.unit, required this.indexed});

  ClassDeclaration? findClass(String? className) {
    return unit.declarations.whereType<ClassDeclaration>().firstWhereOrNull(
          (c) => c.name.lexeme == className,
        );
  }

  MethodDeclaration? findMethod(ClassDeclaration? cls, String methodName) {
    return cls?.members.whereType<MethodDeclaration>().firstWhereOrNull(
          (m) => m.name.lexeme == methodName,
        );
  }

  VariableDeclaration? findProperty(
    ClassDeclaration? cls,
    String propertyName,
  ) {
    final field = cls?.members.whereType<FieldDeclaration>().firstWhereOrNull(
          (m) => m.fields.variables.any((v) => v.name.lexeme == propertyName),
        );

    if (field == null) return null;
    return field.fields.variables.firstWhere(
      (v) => v.name.lexeme == propertyName,
    );
  }

  VariableDeclaration? findTopLevelVariable(String name) {
    return unit.declarations
        .whereType<VariableDeclaration>()
        .firstWhereOrNull((v) => v.name.lexeme == name);
  }

  /// Tries to parse a value from an expression.
  ///
  /// Returns null if the expression is not a valid constructor call.
  ///
  /// Returns the name of the constructor and a map of the named arguments.
  (
    String constructorName,
    Iterable<(String name, String expression, NamedExpression argument)> named,
  )? parseExpression(Expression expression) {
    expression = expression.unParenthesized;

    final children = expression.childEntities;
    if (children.isEmpty) return null;

    if (children.elementAt(0) is SimpleIdentifier &&
        children.elementAt(1) is ArgumentList) {
      final name = children.elementAt(0) as SimpleIdentifier;
      final args = children.elementAt(1) as ArgumentList;

      assert(
        args.arguments.every((e) => e is NamedExpression),
        'Only named arguments are supported',
      );

      final arguments = args.arguments.cast<NamedExpression>();

      return (
        name.name,
        arguments.map((argument) {
          return (
            argument.name.label.name,
            argument.expression.toSource(),
            argument,
          );
        })
      );
    } else {
      return null;
    }
  }
}
