part of 'show_bloc.dart';

class ShowState extends Equatable {
  final List<String> urls;
  final bool loading;
  final bool error;
  final int currentIndex;
  final Set<int> initializedIndices;
  final bool isLoadingMore;

  /// Provide a callback for pagination
  final Future<List<String>> Function()? fetchMoreCallback;

  const ShowState({
    required this.urls,
    required this.loading,
    required this.error,
    required this.currentIndex,
    required this.initializedIndices,
    required this.isLoadingMore,
    this.fetchMoreCallback,
  });

  const ShowState.initial()
      : urls = const [],
        loading = false,
        error = false,
        currentIndex = 0,
        initializedIndices = const {},
        isLoadingMore = false,
        fetchMoreCallback = null;

  ShowState copyWith({
    List<String>? urls,
    bool? loading,
    bool? error,
    int? currentIndex,
    Set<int>? initializedIndices,
    bool? isLoadingMore,
    Future<List<String>> Function()? fetchMoreCallback,
  }) {
    return ShowState(
      urls: urls ?? this.urls,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      currentIndex: currentIndex ?? this.currentIndex,
      initializedIndices: initializedIndices ?? this.initializedIndices,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      fetchMoreCallback: fetchMoreCallback ?? this.fetchMoreCallback,
    );
  }

  @override
  List<Object?> get props => [
        urls,
        loading,
        error,
        currentIndex,
        initializedIndices,
        isLoadingMore,
      ];
}
