// lib/blocs/show_bloc/show_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

part 'show_event.dart';
part 'show_state.dart';

class ShowBloc extends Bloc<ShowEvent, ShowState> {
  final Map<int, VideoPlayerController> _controllers = {};

  /// How many neighbors to preload on each side (±_preloadDistance).
  final int _preloadDistance = 5;

  /// Keep controllers within this distance (dispose others).
  final int _retainDistance = 6;

  ShowBloc() : super(const ShowState.initial()) {
    on<LoadVideos>(_onLoadVideos);
    on<PageChanged>(_onPageChanged);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<DisposeAll>(_onDisposeAll);
  }

  VideoPlayerController? controllerForIndex(int index) => _controllers[index];

  Future<void> _onLoadVideos(LoadVideos event, Emitter<ShowState> emit) async {
    emit(state.copyWith(urls: event.urls, loading: true, error: false));

    if (event.urls.isEmpty) {
      emit(state.copyWith(loading: false, error: true));
      return;
    }

    final int start = 0;

    // Ensure controller for start exists and init sequentially.
    await _ensureControllerInitialized(start, emit);

    // Preload neighbors sequentially to reduce spikes.
    await _preloadAround(start, emit);

    // Play start index
    _playControllerAt(start);

    // Trim any far controllers
    _trimControllers(start, emit);

    emit(state.copyWith(loading: false, currentIndex: start));
  }

  Future<void> _onPageChanged(PageChanged event, Emitter<ShowState> emit) async {
    if (state.urls.isEmpty) return;
    final newIndex = event.index.clamp(0, state.urls.length - 1);

    // Pause others quickly
    _pauseAllExcept(newIndex);

    // Ensure this index initialized
    await _ensureControllerInitialized(newIndex, emit);

    // Preload neighbors sequentially
    await _preloadAround(newIndex, emit);

    // Play new index
    _playControllerAt(newIndex);

    // Trim controllers far away to keep memory bounded
    _trimControllers(newIndex, emit);

    emit(state.copyWith(currentIndex: newIndex));
  }

  Future<void> _onTogglePlayPause(TogglePlayPause event, Emitter<ShowState> emit) async {
    final ctrl = _controllers[event.index];
    if (ctrl == null) return;

    try {
      if (ctrl.value.isPlaying) {
        await ctrl.pause();
      } else {
        if (!ctrl.value.isInitialized) await ctrl.initialize();
        await ctrl.play();
      }
    } catch (e) {
      // On failure, remove controller
      try {
        _controllers[event.index]?.dispose();
      } catch (_) {}
      _controllers.remove(event.index);
      if (_controllers.isEmpty) emit(state.copyWith(error: true));
    }
  }

  Future<void> _onDisposeAll(DisposeAll event, Emitter<ShowState> emit) async {
    for (final c in _controllers.values) {
      try {
        await c.pause();
      } catch (_) {}
      try {
        c.dispose();
      } catch (_) {}
    }
    _controllers.clear();
    emit(const ShowState.initial());
  }

  Future<void> _ensureControllerInitialized(int index, Emitter<ShowState> emit) async {
    if (index < 0 || index >= state.urls.length) return;
    if (_controllers.containsKey(index)) return;

    final url = state.urls[index];
    try {
      final controller = VideoPlayerController.network(url)
        ..setLooping(true)
        ..setVolume(1.0);
      // store prior to initialize so other widgets can access
      _controllers[index] = controller;

      // initialize (sequential)
      await controller.initialize();

      final updated = Set<int>.from(state.initializedIndices)..add(index);
      emit(state.copyWith(initializedIndices: updated));
    } catch (e) {
      // cleanup on failure
      try {
        _controllers[index]?.dispose();
      } catch (_) {}
      _controllers.remove(index);
      if (_controllers.isEmpty) emit(state.copyWith(error: true));
    }
  }

  /// Sequential preload within [_preloadDistance]
  Future<void> _preloadAround(int center, Emitter<ShowState> emit) async {
    for (int offset = -_preloadDistance; offset <= _preloadDistance; offset++) {
      final idx = center + offset;
      if (idx >= 0 && idx < state.urls.length && !_controllers.containsKey(idx)) {
        await _ensureControllerInitialized(idx, emit);
      }
    }
  }

  void _playControllerAt(int index) {
    final ctrl = _controllers[index];
    if (ctrl == null) return;

    // Pause playing others immediately
    for (final entry in _controllers.entries) {
      if (entry.key != index && entry.value.value.isPlaying) {
        try {
          entry.value.pause();
        } catch (_) {}
      }
    }

    // Play current controller (if not initialized, initialize then play)
    if (!ctrl.value.isInitialized) {
      ctrl.initialize().then((_) {
        try {
          ctrl.play();
        } catch (_) {}
      });
    } else {
      try {
        ctrl.play();
      } catch (_) {}
    }
  }

  void _pauseAllExcept(int index) {
    for (final entry in _controllers.entries) {
      if (entry.key != index && entry.value.value.isPlaying) {
        try {
          entry.value.pause();
        } catch (_) {}
      }
    }
  }

  /// Dispose controllers farther than [_retainDistance] from center
  void _trimControllers(int center, Emitter<ShowState> emit) {
    final toRemove = <int>[];
    for (final idx in _controllers.keys) {
      if ((idx - center).abs() > _retainDistance) {
        toRemove.add(idx);
      }
    }
    if (toRemove.isEmpty) return;

    for (final idx in toRemove) {
      try {
        _controllers[idx]?.pause();
      } catch (_) {}
      try {
        _controllers[idx]?.dispose();
      } catch (_) {}
      _controllers.remove(idx);
    }

    final updated = Set<int>.from(state.initializedIndices)..removeAll(toRemove);
    emit(state.copyWith(initializedIndices: updated));
  }

  @override
  Future<void> close() {
    for (final c in _controllers.values) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _controllers.clear();
    return super.close();
  }
}



// import 'dart:async';
// import 'package:bloc/bloc.dart';
//
// import 'package:equatable/equatable.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter/foundation.dart';
//
//
//
// part 'show_event.dart';
// part 'show_state.dart';
//
// class ShowBloc extends Bloc<ShowEvent, ShowState> {
//   final Map<int, VideoPlayerController> _controllers = {};
//   final int _preloadDistance = 1;
//
//   ShowBloc() : super(const ShowState.initial()) {
//     on<LoadVideos>(_onLoadVideos);
//     on<PageChanged>(_onPageChanged);
//     on<TogglePlayPause>(_onTogglePlayPause);
//     on<DisposeAll>(_onDisposeAll);
//   }
//
//   VideoPlayerController? controllerForIndex(int index) => _controllers[index];
//
//   Future<void> _onLoadVideos(LoadVideos event, Emitter<ShowState> emit) async {
//     emit(state.copyWith(urls: event.urls, loading: true, error: false));
//     if (event.urls.isEmpty) {
//       emit(state.copyWith(loading: false, error: true));
//       return;
//     }
//
//     final int start = 0;
//     await _ensureControllerInitialized(start, emit);
//     await _preloadAround(start, emit);
//     _playControllerAt(start);
//     emit(state.copyWith(loading: false, currentIndex: start));
//   }
//
//   Future<void> _onPageChanged(PageChanged event, Emitter<ShowState> emit) async {
//     final newIndex = event.index.clamp(0, state.urls.length - 1);
//     _pauseAllExcept(newIndex);
//     await _ensureControllerInitialized(newIndex, emit);
//     await _preloadAround(newIndex, emit);
//     _playControllerAt(newIndex);
//     emit(state.copyWith(currentIndex: newIndex));
//   }
//
//   Future<void> _onTogglePlayPause(TogglePlayPause event, Emitter<ShowState> emit) async {
//     final ctrl = _controllers[event.index];
//     if (ctrl == null) return;
//     if (ctrl.value.isPlaying) {
//       await ctrl.pause();
//     } else {
//       if (!ctrl.value.isInitialized) await ctrl.initialize();
//       await ctrl.play();
//     }
//   }
//
//   Future<void> _onDisposeAll(DisposeAll event, Emitter<ShowState> emit) async {
//     for (final c in _controllers.values) {
//       try {
//         await c.pause();
//       } catch (_) {}
//       c.dispose();
//     }
//     _controllers.clear();
//     emit(const ShowState.initial());
//   }
//
//   Future<void> _ensureControllerInitialized(int index, Emitter<ShowState> emit) async {
//     if (index < 0 || index >= state.urls.length) return;
//     if (_controllers.containsKey(index)) return;
//
//     final url = state.urls[index];
//     try {
//       final controller = VideoPlayerController.network(url)
//         ..setLooping(true)
//         ..setVolume(1.0);
//       _controllers[index] = controller;
//       await controller.initialize();
//       final updated = Set<int>.from(state.initializedIndices)..add(index);
//       emit(state.copyWith(initializedIndices: updated));
//     } catch (e) {
//       _controllers.remove(index);
//       if (_controllers.isEmpty) emit(state.copyWith(error: true));
//     }
//   }
//
//   Future<void> _preloadAround(int center, Emitter<ShowState> emit) async {
//     final futures = <Future>[];
//     for (int offset = -_preloadDistance; offset <= _preloadDistance; offset++) {
//       final idx = center + offset;
//       if (idx >= 0 && idx < state.urls.length && !_controllers.containsKey(idx)) {
//         futures.add(_ensureControllerInitialized(idx, emit));
//       }
//     }
//     await Future.wait(futures);
//   }
//
//   void _playControllerAt(int index) {
//     final ctrl = _controllers[index];
//     if (ctrl == null) return;
//     for (final entry in _controllers.entries) {
//       if (entry.key != index && entry.value.value.isPlaying) {
//         entry.value.pause();
//       }
//     }
//     if (!ctrl.value.isInitialized) {
//       ctrl.initialize().then((_) => ctrl.play());
//     } else {
//       ctrl.play();
//     }
//   }
//
//   void _pauseAllExcept(int index) {
//     for (final entry in _controllers.entries) {
//       if (entry.key != index && entry.value.value.isPlaying) {
//         entry.value.pause();
//       }
//     }
//   }
//
//   @override
//   Future<void> close() {
//     for (final c in _controllers.values) {
//       try {
//         c.dispose();
//       } catch (_) {}
//     }
//     _controllers.clear();
//     return super.close();
//   }
// }
