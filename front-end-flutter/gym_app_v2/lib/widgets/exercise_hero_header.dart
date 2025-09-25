import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';
import 'app_snack_bar.dart';

/// Reusable hero header for exercise-related screens (configure & detail)
/// Provides: background (image or gradient), centered play button placeholder,
/// back button, optional action widget (e.g., menu), title, and muscle group chips.
class ExerciseHeroHeader extends StatelessWidget {
  final String title;
  final List<String>
  muscleGroups; // pass already limited (or full; we cap at 4)
  final VoidCallback onBack;
  final VoidCallback? onPlay;
  final Widget? action; // e.g., actions menu
  final String? backgroundImage;
  final double height;
  final bool loadingTitle;

  const ExerciseHeroHeader({
    super.key,
    required this.title,
    required this.muscleGroups,
    required this.onBack,
    this.onPlay,
    this.action,
    this.backgroundImage,
    this.height = 340,
    this.loadingTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final mg = muscleGroups.take(4).toList();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: (backgroundImage != null && backgroundImage!.isNotEmpty)
                ? Image.asset(
                    backgroundImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientFallback(),
                  )
                : _gradientFallback(),
          ),
          Positioned.fill(
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
          // Play button placeholder
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap:
                    onPlay ??
                    () => AppSnackBar.showInfo(
                      context,
                      'Video demo chưa khả dụng',
                    ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacityRatio(0.4),
                      width: 2,
                    ),
                    color: Colors.white.withOpacityRatio(0.15),
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
          ),
          Positioned(
            left: 4,
            top: MediaQuery.of(context).padding.top + 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),
          ),
          if (action != null)
            Positioned(
              right: 4,
              top: MediaQuery.of(context).padding.top + 4,
              child: action!,
            ),
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
                    loadingTitle ? 'Đang tải...' : title,
                    key: ValueKey(loadingTitle ? 'loading' : title),
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
                    children: [for (final g in mg) _MuscleGroupChip(label: g)],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
