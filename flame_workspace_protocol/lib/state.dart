class const GameState({required final bool paused}) {
  const GameState.initial({bool paused = false}) : this(paused: paused);

  static GameState fromMap(Map<String, dynamic> map) {
    final paused = map['paused'] as bool?;
    if (paused == null) throw ArgumentError('The paused key is required');

    return GameState(paused: paused);
  }

  Map<String, dynamic> toMap() {
    return {'paused': paused};
  }

  GameState copyWith({bool? paused}) {
    return GameState(paused: paused ?? this.paused);
  }
}
