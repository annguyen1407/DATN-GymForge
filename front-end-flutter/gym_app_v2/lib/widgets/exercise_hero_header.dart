import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../core/extensions/color_extensions.dart';

/// Reusable hero header for exercise-related screens (configure & detail)
/// Provides: background (image or gradient), centered play button placeholder,
/// back button, optional action widget (e.g., menu), title, and muscle group chips.
class ExerciseHeroHeader extends StatefulWidget {
  final String title;
  final List<String>
  muscleGroups; // pass already limited (or full; we cap at 4)
  final VoidCallback onBack;
  final Widget? action; // e.g., actions menu
  final String? backgroundImage;
  final double height;
  final bool loadingTitle;
  final String? videoUrl; // full YouTube URL
  final bool autoplay;
  final bool showProgressBar; // control showing a thin custom progress bar

  const ExerciseHeroHeader({
    super.key,
    required this.title,
    required this.muscleGroups,
    required this.onBack,
    this.action,
    this.backgroundImage,
    this.height = 340,
    this.loadingTitle = false,
    this.videoUrl,
    this.autoplay = false,
    this.showProgressBar = false,
  });

  @override
  State<ExerciseHeroHeader> createState() => _ExerciseHeroHeaderState();
}

class _ExerciseHeroHeaderState extends State<ExerciseHeroHeader> {
  YoutubePlayerController? _ytController;
  bool _showPlayer = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty) {
      _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl!.trim());
      if (widget.autoplay && _videoId != null) {
        _initController();
        _showPlayer = true;
      }
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseHeroHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If previously no video and now has one, update state so thumbnail appears.
    if ((oldWidget.videoUrl == null || oldWidget.videoUrl!.isEmpty) &&
        widget.videoUrl != null &&
        widget.videoUrl!.trim().isNotEmpty) {
      final newId = YoutubePlayer.convertUrlToId(widget.videoUrl!.trim());
      if (newId != null && newId != _videoId) {
        setState(() {
          _videoId = newId;
          _showPlayer = false; // start from thumbnail again
          _ytController?.dispose();
          _ytController = null;
        });
      }
    }
  }

  void _initController() {
    if (_ytController != null || _videoId == null) return;
    _ytController = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true,
        disableDragSeek: false,
        hideControls: false,
      ),
    );
    _ytController!.addListener(_controllerListener);
  }

  void _controllerListener() {
    if (!mounted || _ytController == null) return;
    final value = _ytController!.value;
    // Only act on explicit ended state to avoid early reset when duration not loaded yet.
    if (value.playerState == PlayerState.ended) {
      if (_showPlayer) {
        setState(() => _showPlayer = false);
      }
    }
  }

  @override
  void dispose() {
    _ytController?.removeListener(_controllerListener);
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mg = widget.muscleGroups.take(4).toList();
    final playing = _showPlayer && _ytController != null;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          if (!playing)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacityRatio(.25),
                        Colors.black.withOpacityRatio(.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!playing && _videoId != null) _buildVideoLayer(),
          Positioned(
            left: 4,
            top: MediaQuery.of(context).padding.top + 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
          ),
          if (widget.action != null)
            Positioned(
              right: 4,
              top: MediaQuery.of(context).padding.top + 4,
              child: widget.action!,
            ),
          if (!playing)
            Positioned(
              bottom: 18,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.loadingTitle ? 'Đang tải...' : widget.title,
                      key: ValueKey(
                        widget.loadingTitle ? 'loading' : widget.title,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (mg.isNotEmpty) const SizedBox(height: 12),
                  if (mg.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in mg) _MuscleGroupChip(label: g),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_showPlayer && _ytController != null) {
      final player = YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator:
            false, // disable built-in to avoid duplicate
        onEnded: (_) {
          if (mounted && _showPlayer) setState(() => _showPlayer = false);
        },
      );
      if (!widget.showProgressBar) return player;
      // Custom simple linear progress (thin) overlay at bottom
      return Stack(
        fit: StackFit.expand,
        children: [
          player,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ytController == null
                ? const SizedBox.shrink()
                : AnimatedBuilder(
                    animation: _ytController!,
                    builder: (_, __) {
                      final v = _ytController!.value;
                      final total = v.metaData.duration.inMilliseconds;
                      final pos = v.position.inMilliseconds;
                      final pct = (total == 0)
                          ? 0.0
                          : (pos / total).clamp(0.0, 1.0);
                      return LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.pinkAccent,
                        ),
                        minHeight: 3,
                      );
                    },
                  ),
          ),
        ],
      );
    }
    // Thumbnail or fallback gradient
    if (_videoId != null) {
      final thumb = 'https://img.youtube.com/vi/${_videoId!}/hqdefault.jpg';
      return GestureDetector(
        onTap: () {
          _initController();
          setState(() => _showPlayer = true);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumb,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientFallback(),
              loadingBuilder: (c, w, p) => p == null
                  ? w
                  : const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.pinkAccent,
                      ),
                    ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacityRatio(0.4),
                      width: 2,
                    ),
                    color: Colors.black.withOpacity(0.25),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacityRatio(0.92),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Background image original
    if (widget.backgroundImage != null && widget.backgroundImage!.isNotEmpty) {
      return Image.asset(
        widget.backgroundImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientFallback(),
      );
    }
    return _gradientFallback();
  }

  Widget _buildVideoLayer() {
    // Layer reserved for overlay stuff if cần (hiện đang xử lý trong background)
    return const SizedBox.shrink();
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2F33), Color(0xFF181A1D)],
        ),
      ),
    );
  }
}

/// Uniform muscle group chip (no highlighted first item)
class _MuscleGroupChip extends StatelessWidget {
  final String label;
  const _MuscleGroupChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacityRatio(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacityRatio(.18),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
