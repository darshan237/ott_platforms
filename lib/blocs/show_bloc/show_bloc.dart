import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:video_player/video_player.dart';

part 'show_event.dart';
part 'show_state.dart';

class ShowBloc extends Bloc<ShowEvent, ShowState> {
  final Map<int, VideoPlayerController> _controllers = {};

  /// Sliding window sizes
  final int preloadAhead = 1;   // preload 1 next reel
  final int preloadBehind = 1;  // preload 1 previous reel
  final int retainAhead = 3;    // keep only 3 next reels alive
  final int retainBehind = 2;   // keep only 2 previous reels alive

  ShowBloc() : super(const ShowState.initial()) {
    on<LoadVideos>(_onLoadVideos);
    on<LoadMoreVideos>(_onLoadMoreVideos);
    on<PageChanged>(_onPageChanged);
    on<DisposeAll>(_onDisposeAll);
  }

  VideoPlayerController? controllerForIndex(int index) => _controllers[index];

  // ------------------------------------------
  // ✅ INITIAL LOAD
  // ------------------------------------------
  Future<void> _onLoadVideos(LoadVideos event, Emitter<ShowState> emit) async {
    emit(state.copyWith(urls: event.urls, loading: true));

    if (event.urls.isEmpty) {
      emit(state.copyWith(loading: false, error: true));
      return;
    }

    await _initializeIndex(0, emit);
    _playIndex(0);

    // Preload nearby
    await _preloadAround(0, emit);

    emit(state.copyWith(currentIndex: 0, loading: false));
  }

  // ------------------------------------------
  // ✅ PAGINATION — Load more URLs when needed
  // ------------------------------------------
  Future<void> _onLoadMoreVideos(
      LoadMoreVideos event, Emitter<ShowState> emit) async {
    if (state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    // You replace this with Firestore/API call
    final newUrls = await event.fetchMore();

    if (newUrls.isNotEmpty) {
      final updated = List<String>.from(state.urls)..addAll(newUrls);
      emit(state.copyWith(urls: updated));
    }

    emit(state.copyWith(isLoadingMore: false));
  }

  // ------------------------------------------
  // ✅ WHEN USER SCROLLS
  // ------------------------------------------
  Future<void> _onPageChanged(PageChanged event, Emitter<ShowState> emit) async {
    final index = event.index;

    if (index < 0 || index >= state.urls.length) return;

    // load next 5 when user reaches last 5
    if (index >= state.urls.length - 5) {
      add(LoadMoreVideos(state.fetchMoreCallback));
    }

    // Initialize video
    await _initializeIndex(index, emit);

    // Preload neighbors
    await _preloadAround(index, emit);

    // Play current index
    _playIndex(index);

    // Dispose far videos
    _trimControllers(index, emit);

    emit(state.copyWith(currentIndex: index));
  }

  // ------------------------------------------
  // ✅ INITIALIZE VIDEO
  // ------------------------------------------
  Future<void> _initializeIndex(int index, Emitter<ShowState> emit) async {
    if (_controllers.containsKey(index)) return;

    final url = state.urls[index];
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controllers[index] = controller;

      await controller.initialize();
      controller.setLooping(true);

      final updated = {...state.initializedIndices, index};
      emit(state.copyWith(initializedIndices: updated));
    } catch (e) {
      _controllers.remove(index);
    }
  }

  // ------------------------------------------
  // ✅ PRELOAD NEARBY VIDEOS
  // ------------------------------------------
  Future<void> _preloadAround(int center, Emitter<ShowState> emit) async {
    for (int i = center - preloadBehind; i <= center + preloadAhead; i++) {
      if (i >= 0 && i < state.urls.length && !_controllers.containsKey(i)) {
        await _initializeIndex(i, emit);
      }
    }
  }

  // ------------------------------------------
  // ✅ PLAY CURRENT INDEX
  // ------------------------------------------
  void _playIndex(int index) {
    for (final entry in _controllers.entries) {
      if (entry.key == index) {
        if (!entry.value.value.isPlaying) entry.value.play();
      } else {
        entry.value.pause();
      }
    }
  }

  // ------------------------------------------
  // ✅ REMOVE OLD CONTROLLERS
  // ------------------------------------------
  void _trimControllers(int center, Emitter<ShowState> emit) {
    final remove = <int>[];

    for (final idx in _controllers.keys) {
      if (idx < center - retainBehind || idx > center + retainAhead) {
        remove.add(idx);
      }
    }

    for (final idx in remove) {
      _controllers[idx]?.dispose();
      _controllers.remove(idx);
    }

    final updated = Set<int>.from(state.initializedIndices)..removeAll(remove);
    emit(state.copyWith(initializedIndices: updated));
  }

  // ------------------------------------------
  // ✅ DISPOSE ALL
  // ------------------------------------------
  Future<void> _onDisposeAll(DisposeAll event, Emitter<ShowState> emit) async {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    emit(const ShowState.initial());
  }
}
