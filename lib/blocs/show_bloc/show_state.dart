part of 'show_bloc.dart';

class ShowState {
  final List<String> urls;
  final int currentIndex;
  final bool loading;
  final Set<int> initializedIndices;
  final bool error;

  const ShowState({
    required this.urls,
    required this.currentIndex,
    required this.loading,
    required this.initializedIndices,
    required this.error,
  });

  const ShowState.initial()
      : urls = const [],
        currentIndex = 0,
        loading = false,
        initializedIndices = const {},
        error = false;

  ShowState copyWith({
    List<String>? urls,
    int? currentIndex,
    bool? loading,
    Set<int>? initializedIndices,
    bool? error,
  }) {
    return ShowState(
      urls: urls ?? this.urls,
      currentIndex: currentIndex ?? this.currentIndex,
      loading: loading ?? this.loading,
      initializedIndices: initializedIndices ?? this.initializedIndices,
      error: error ?? this.error,
    );
  }
}
