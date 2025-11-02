// lib/ui/pages/shows/video_item.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:dd_box/blocs/show_bloc/show_bloc.dart';
import 'package:dd_box/ui/widgets/action_button.dart';

class VideoItem extends StatefulWidget {
  final int index;
  final List<String> videoUrls;

  const VideoItem({
    required this.index,
    required this.videoUrls,
    super.key,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late ShowBloc _bloc;
  VideoPlayerController? _controller;

  bool _isMuted = false;
  bool _showControls = false;
  Timer? _controlsTimer;

  late AnimationController _heartAnim;
  bool _showHeart = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ShowBloc>();

    _controller = _bloc.controllerForIndex(widget.index);

    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.index != widget.index) {
      _controller = _bloc.controllerForIndex(widget.index);
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _heartAnim.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // ✅ Show UI Controls for 3 seconds
  // ---------------------------------------------------------
  void _showTempControls() {
    setState(() => _showControls = true);

    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  // ---------------------------------------------------------
  // ✅ Play / Pause
  // ---------------------------------------------------------
  void _togglePlayPause() {
    if (_controller == null) return;

    _bloc.add(TogglePlayPause(widget.index));
    _showTempControls();
  }

  // ---------------------------------------------------------
  // ✅ Mute / Unmute
  // ---------------------------------------------------------
  void _toggleMute() {
    if (_controller == null) return;
    setState(() => _isMuted = !_isMuted);
    _controller!.setVolume(_isMuted ? 0 : 1);
    _showTempControls();
  }

  // ---------------------------------------------------------
  // ✅ Double Tap Heart
  // ---------------------------------------------------------
  void _onDoubleTap() {
    setState(() => _showHeart = true);
    _heartAnim.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  // ---------------------------------------------------------
  // ✅ Buffer Indicator
  // ---------------------------------------------------------
  Widget _buildBuffering(VideoPlayerValue v) {
    if (!v.isBuffering) return const SizedBox.shrink();
    return const Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }

  // ---------------------------------------------------------
  // ✅ Pause Icon
  // ---------------------------------------------------------
  Widget _buildPlayPauseOverlay(VideoPlayerValue v) {
    if (v.isPlaying) return const SizedBox.shrink();
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(16),
        child: const Icon(Icons.play_arrow, size: 60, color: Colors.white),
      ),
    );
  }

  // ---------------------------------------------------------
  // ✅ Progress Bar
  // ---------------------------------------------------------
  Widget _buildProgress(VideoPlayerValue v) {
    final duration = v.duration;
    final position = v.position;

    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    final progress = position.inMilliseconds / duration.inMilliseconds;

    return Positioned(
      left: 8,
      right: 8,
      bottom: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _controller = _bloc.controllerForIndex(widget.index);

    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTap,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _controller!,
        builder: (context, v, child) {
          if (!v.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // ✅ If this is the current reel, ensure it plays
          if (_bloc.state.currentIndex == widget.index && !v.isPlaying) {
            try {
              _controller!.play();
            } catch (_) {}
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // ---------------------------------------------------------
              // ✅ Fullscreen Video (IG Style)
              // ---------------------------------------------------------
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: v.size.width,
                  height: v.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),

              _buildBuffering(v),
              _buildPlayPauseOverlay(v),
              _buildProgress(v),

              // ---------------------------------------------------------
              // ✅ Mute Button
              // ---------------------------------------------------------
              Positioned(
                top: 40,
                left: 12,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: InkWell(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
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

              // ---------------------------------------------------------
              // ✅ Page Indicator
              // ---------------------------------------------------------
              Positioned(
                top: 48,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${widget.index + 1}/${widget.videoUrls.length}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              // ---------------------------------------------------------
              // ✅ Bottom Left Caption
              // ---------------------------------------------------------
              Positioned(
                left: 12,
                bottom: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "AI Billionaire",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Short drama clip",
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------------
              // ✅ Right Action Buttons
              // ---------------------------------------------------------
              Positioned(
                right: 12,
                bottom: 80,
                child: Column(
                  children: const [
                    ActionButton(icon: Icons.favorite, label: "1.2K"),
                    SizedBox(height: 16),
                    ActionButton(icon: Icons.comment, label: "120"),
                    SizedBox(height: 16),
                    ActionButton(icon: Icons.share, label: "Share"),
                  ],
                ),
              ),

              // ---------------------------------------------------------
              // ✅ Double Tap Heart Animation
              // ---------------------------------------------------------
              if (_showHeart)
                Center(
                  child: ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.4).animate(
                      CurvedAnimation(
                          parent: _heartAnim, curve: Curves.elasticOut),
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 120,
                      color: Colors.redAccent.withOpacity(0.9),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
