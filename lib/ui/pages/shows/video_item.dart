// lib/ui/pages/shows/video_item.dart
import 'dart:async';
import 'package:dd_box/blocs/show_bloc/show_bloc.dart';
import 'package:dd_box/ui/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VideoItem extends StatefulWidget {
  final int index;
  final List<String> videoUrls;
  const VideoItem({required this.index, required this.videoUrls, super.key});

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ShowBloc _bloc;
  VideoPlayerController? _controller;
  VoidCallback? _controllerListener;

  bool _showControls = false;
  Timer? _hideControlsTimer;
  bool _isMuted = false;
  bool _showHeart = false;
  late AnimationController _heartAnimController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<ShowBloc>(context);
    _controller = _bloc.controllerForIndex(widget.index);
    _attachControllerListener();

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reassignControllerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _reassignControllerIfNeeded();
    }
  }

  void _reassignControllerIfNeeded() {
    // remove previous listener
    _removeControllerListener();

    // re-acquire controller
    _controller = _bloc.controllerForIndex(widget.index);

    // attach listener again
    _attachControllerListener();
  }

  void _attachControllerListener() {
    if (_controller == null) return;
    // ensure listener only added once
    _controllerListener = () {
      final val = _controller?.value;
      if (val == null) return;

      // When controller gets initialized and this item is the current index,
      // ensure it plays automatically (helps when initialization completes later).
      if (val.isInitialized && _bloc.state.currentIndex == widget.index) {
        if (!_controller!.value.isPlaying) {
          try {
            _controller!.play();
          } catch (_) {}
        }
      }

      // If controller becomes buffering / playing etc, we can setState for overlays.
      if (mounted) setState(() {});
    };

    _controller?.addListener(_controllerListener!);
  }

  void _removeControllerListener() {
    if (_controller != null && _controllerListener != null) {
      try {
        _controller!.removeListener(_controllerListener!);
      } catch (_) {}
      _controllerListener = null;
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _heartAnimController.dispose();
    _removeControllerListener();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    _bloc.add(TogglePlayPause(widget.index));
    // show controls briefly whenever user toggles
    _showTempControls();
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      _showTempControls();
    });
  }

  void _showTempControls() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onDoubleTap() {
    setState(() => _showHeart = true);
    _heartAnimController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
    // TODO: dispatch like event if needed
  }

  Widget _buildBufferingOverlay(VideoPlayerValue value) {
    if (!value.isBuffering) return const SizedBox.shrink();
    return const Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }

  Widget _buildPlayIconIfPaused(VideoPlayerValue value) {
    if (value.isPlaying) return const SizedBox.shrink();
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Icon(Icons.play_arrow, size: 60, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProgressBar(VideoPlayerValue value) {
    final duration = value.duration;
    final position = value.position;
    if (duration == null || duration.inMilliseconds == 0) {
      return const SizedBox.shrink();
    }
    final progress = position.inMilliseconds / duration.inMilliseconds;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _showTempControls(),
          onHorizontalDragUpdate: (details) {
            if (_controller == null || !value.isInitialized) return;
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final local = box.globalToLocal(details.globalPosition);
            final w = box.size.width;
            var relative = (local.dx / w).clamp(0.0, 1.0);
            final seekTo = Duration(milliseconds: (value.duration!.inMilliseconds * relative).toInt());
            _controller!.seekTo(seekTo);
          },
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    // Reacquire controller every build in case bloc created it later.
    _controller = _bloc.controllerForIndex(widget.index);
    // If listener not attached (controller changed), attach again.
    if (_controller != null && _controllerListener == null) {
      _attachControllerListener();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller == null)
            const Center(child: CircularProgressIndicator())
          else
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, child) {
                if (!value.isInitialized) {
                  return const Center(child: CircularProgressIndicator());
                }

                // When initialized and this is current index, ensure playing.
                if (_bloc.state.currentIndex == widget.index && !value.isPlaying) {
                  // try play (safe)
                  try {
                    _controller!.play();
                  } catch (_) {}
                }

                final video = FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    video,
                    _buildBufferingOverlay(value),
                    _buildPlayIconIfPaused(value),
                    _buildProgressBar(value),
                    Positioned(
                      top: 40,
                      left: 12,
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: InkWell(
                          onTap: _toggleMute,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("${widget.index + 1}/${widget.videoUrls.length}", style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 64,
                      right: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("AI Billionaire", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text("Short drama clip", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          ActionButton(icon: Icons.favorite, label: "1.2K"),
                          SizedBox(height: 16),
                          ActionButton(icon: Icons.comment, label: "120"),
                          SizedBox(height: 16),
                          ActionButton(icon: Icons.share, label: "Share"),
                        ],
                      ),
                    ),
                    if (_showHeart)
                      Center(
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.4).animate(
                            CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
                          ),
                          child: Opacity(
                            opacity: 0.95,
                            child: Icon(Icons.favorite, size: 120, color: Colors.redAccent.withOpacity(0.95)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}



// // lib/video_item.dart
// import 'dart:async';
// import 'package:dd_box/blocs/show_bloc/show_bloc.dart';
// import 'package:dd_box/ui/widgets/action_button.dart';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
//
// class VideoItem extends StatefulWidget {
//   final int index;
//   final List<String> videoUrls;
//   const VideoItem({required this.index, required this.videoUrls, super.key});
//
//   @override
//   State<VideoItem> createState() => _VideoItemState();
// }
//
// class _VideoItemState extends State<VideoItem> with SingleTickerProviderStateMixin {
//   late ShowBloc _bloc;
//   VideoPlayerController? _controller;
//   bool _showControls = false;
//   Timer? _hideControlsTimer;
//   bool _isMuted = false;
//   bool _showHeart = false;
//   late AnimationController _heartAnimController;
//
//   @override
//   void initState() {
//     super.initState();
//     _bloc = BlocProvider.of<ShowBloc>(context);
//     _controller = _bloc.controllerForIndex(widget.index);
//
//     // This widget may be built before the bloc initializes controller for this index.
//     // So we reassign in didChangeDependencies in case it becomes available later.
//     _heartAnimController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Re-acquire controller every time dependencies change.
//     _controller = _bloc.controllerForIndex(widget.index);
//   }
//
//   @override
//   void dispose() {
//     _hideControlsTimer?.cancel();
//     _heartAnimController.dispose();
//     super.dispose();
//   }
//
//   void _togglePlayPause() {
//     if (_controller == null) return;
//     if (_controller!.value.isPlaying) {
//       _bloc.add(TogglePlayPause(widget.index));
//       _showTempControls();
//     } else {
//       _bloc.add(TogglePlayPause(widget.index));
//       _startHideControlsTimer();
//     }
//   }
//
//   void _toggleMute() {
//     if (_controller == null) return;
//     setState(() {
//       _isMuted = !_isMuted;
//       _controller!.setVolume(_isMuted ? 0.0 : 1.0);
//       _showTempControls();
//     });
//   }
//
//   void _showTempControls() {
//     setState(() => _showControls = true);
//     _startHideControlsTimer();
//   }
//
//   void _startHideControlsTimer() {
//     _hideControlsTimer?.cancel();
//     _hideControlsTimer = Timer(const Duration(seconds: 3), () {
//       if (mounted) setState(() => _showControls = false);
//     });
//   }
//
//   void _onDoubleTap() {
//     // animate heart
//     setState(() => _showHeart = true);
//     _heartAnimController.forward(from: 0.0);
//     // hide after animation
//     Future.delayed(const Duration(milliseconds: 700), () {
//       if (mounted) setState(() => _showHeart = false);
//     });
//     // TODO: send "like" to backend or bloc if desired
//   }
//
//   Widget _buildBufferingOverlay(VideoPlayerValue value) {
//     if (!value.isBuffering) return const SizedBox.shrink();
//     return const Center(
//       child: SizedBox(
//         width: 48,
//         height: 48,
//         child: CircularProgressIndicator(strokeWidth: 3),
//       ),
//     );
//   }
//
//   Widget _buildPlayIconIfPaused(VideoPlayerValue value) {
//     if (value.isPlaying) return const SizedBox.shrink();
//     return Center(
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.25),
//           shape: BoxShape.circle,
//         ),
//         child: const Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Icon(Icons.play_arrow, size: 60, color: Colors.white),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProgressBar(VideoPlayerValue value) {
//     final duration = value.duration;
//     final position = value.position;
//     if (duration == null || duration.inMilliseconds == 0) {
//       return const SizedBox.shrink();
//     }
//     final progress = position.inMilliseconds / duration.inMilliseconds;
//     return Positioned(
//       left: 0,
//       right: 0,
//       bottom: 12,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//         child: GestureDetector(
//           behavior: HitTestBehavior.opaque,
//           onHorizontalDragStart: (_) => _showTempControls(),
//           onHorizontalDragUpdate: (details) {
//             if (_controller == null || !value.isInitialized) return;
//             final box = context.findRenderObject() as RenderBox?;
//             if (box == null) return;
//             final local = box.globalToLocal(details.globalPosition);
//             final w = box.size.width;
//             var relative = (local.dx / w).clamp(0.0, 1.0);
//             final seekTo = Duration(milliseconds: (value.duration!.inMilliseconds * relative).toInt());
//             _controller!.seekTo(seekTo);
//           },
//           child: Column(
//             children: [
//               LinearProgressIndicator(
//                 value: progress,
//                 minHeight: 3,
//                 backgroundColor: Colors.white.withOpacity(0.15),
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//               const SizedBox(height: 6),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
//                   Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _formatDuration(Duration d) {
//     String two(int n) => n.toString().padLeft(2, '0');
//     final minutes = two(d.inMinutes.remainder(60));
//     final seconds = two(d.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // If controller not yet initialized by bloc, show loader and listen again.
//     _controller = _bloc.controllerForIndex(widget.index);
//
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: () {
//         _togglePlayPause();
//       },
//       onDoubleTap: _onDoubleTap,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video area or loader
//           if (_controller == null)
//             const Center(child: CircularProgressIndicator())
//           else
//             ValueListenableBuilder<VideoPlayerValue>(
//               valueListenable: _controller!,
//               builder: (context, value, child) {
//                 if (!value.isInitialized) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 // Video rendering
//                 final video = FittedBox(
//                   fit: BoxFit.cover,
//                   clipBehavior: Clip.hardEdge,
//                   child: SizedBox(
//                     width: value.size.width,
//                     height: value.size.height,
//                     child: VideoPlayer(_controller!),
//                   ),
//                 );
//
//                 return Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     video,
//                     // Buffering indicator
//                     _buildBufferingOverlay(value),
//                     // Play icon when paused
//                     _buildPlayIconIfPaused(value),
//                     // Progress bar + time
//                     _buildProgressBar(value),
//                     // Mute/Unmute button (top-left)
//                     Positioned(
//                       top: 40,
//                       left: 12,
//                       child: AnimatedOpacity(
//                         opacity: _showControls ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 250),
//                         child: InkWell(
//                           onTap: _toggleMute,
//                           borderRadius: BorderRadius.circular(20),
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.4),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Icon(
//                               _isMuted ? Icons.volume_off : Icons.volume_up,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Top-right index badge
//                     Positioned(
//                       top: 48,
//                       right: 12,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.4),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text("${widget.index + 1}/${widget.videoUrls.length}", style: const TextStyle(color: Colors.white)),
//                       ),
//                     ),
//                     // Bottom-left caption
//                     Positioned(
//                       left: 12,
//                       bottom: 64,
//                       right: 100,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: const [
//                           Text("AI Billionaire", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                           SizedBox(height: 6),
//                           Text("Short drama clip", style: TextStyle(color: Colors.white70, fontSize: 14)),
//                         ],
//                       ),
//                     ),
//                     // Right action buttons
//                     Positioned(
//                       right: 12,
//                       bottom: 80,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           ActionButton(icon: Icons.favorite, label: "1.2K"),
//                           SizedBox(height: 16),
//                           ActionButton(icon: Icons.comment, label: "120"),
//                           SizedBox(height: 16),
//                           ActionButton(icon: Icons.share, label: "Share"),
//                         ],
//                       ),
//                     ),
//                     // Double-tap heart animation
//                     if (_showHeart)
//                       Center(
//                         child: ScaleTransition(
//                           scale: Tween<double>(begin: 0.8, end: 1.4).animate(
//                             CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
//                           ),
//                           child: Opacity(
//                             opacity: 0.95,
//                             child: Icon(Icons.favorite, size: 120, color: Colors.redAccent.withOpacity(0.95)),
//                           ),
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }
// }
