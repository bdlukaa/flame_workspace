import 'dart:async';

/// Debounces filesystem notifications and runs one indexing batch at a time.
class IndexingScheduler {
  IndexingScheduler({
    required this.onBatch,
    this.debounce = const Duration(milliseconds: 200),
  });

  final Future<void> Function(Set<String> changedPaths) onBatch;
  final Duration debounce;
  final Set<String> _pendingPaths = {};
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  int _revision = 0;

  int get revision => _revision;

  void schedule(String path) {
    if (_disposed) return;
    _pendingPaths.add(path);
    _revision++;
    _timer?.cancel();
    _timer = Timer(debounce, _drain);
  }

  Future<void> _drain() async {
    _timer = null;
    if (_disposed || _running || _pendingPaths.isEmpty) return;
    _running = true;
    final batch = Set<String>.of(_pendingPaths);
    _pendingPaths.clear();
    final batchRevision = _revision;
    try {
      await onBatch(batch);
    } finally {
      _running = false;
      if (!_disposed && _pendingPaths.isNotEmpty) {
        if (_revision == batchRevision) {
          unawaited(_drain());
        } else {
          _timer ??= Timer(debounce, _drain);
        }
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pendingPaths.clear();
    while (_running) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
