enum WorkspaceDiagnosticCategory {
  validation,
  project,
  generation,
  import,
  asset,
  runtime,
  synchronization,
}

class WorkspaceDiagnostic {
  const WorkspaceDiagnostic({
    required this.category,
    required this.code,
    required this.operation,
    required this.message,
    this.recovery,
  });

  final WorkspaceDiagnosticCategory category;
  final String code;
  final String operation;
  final String message;
  final String? recovery;

  String get displayMessage =>
      ['${category.name}[$code] $operation: $message', ?recovery].join('\n');

  @override
  String toString() => displayMessage;
}
