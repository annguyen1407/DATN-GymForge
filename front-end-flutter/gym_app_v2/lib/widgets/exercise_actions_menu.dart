import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';

/// Single-action menu (3 dots) for Exercise Detail screen: only provides Delete.
enum ExerciseAction { delete }

typedef ExerciseActionCallback = Future<void> Function(ExerciseAction action);

class ExerciseActionsMenu extends StatelessWidget {
  final ExerciseActionCallback onAction;
  final bool isDeleting;
  final Color? backgroundColor;
  const ExerciseActionsMenu({
    super.key,
    required this.onAction,
    this.isDeleting = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isDeleting) {
      // Show a subtle progress indicator in place of the menu while deleting
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacityRatio(0.08),
          border: Border.all(
            color: Colors.white.withOpacityRatio(0.15),
            width: 1,
          ),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.redAccent,
          ),
        ),
      );
    }
    return PopupMenuButton<ExerciseAction>(
      padding: EdgeInsets.zero,
      tooltip: 'Tùy chọn',
      color: backgroundColor ?? const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacityRatio(0.06), width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.black.withOpacityRatio(0.4),
      icon: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacityRatio(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacityRatio(0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
      ),
      onSelected: (action) => onAction(action),
      itemBuilder: (ctx) => [
        PopupMenuItem<ExerciseAction>(
          value: ExerciseAction.delete,
          child: Row(
            children: const [
              Icon(Icons.delete_forever, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Xoá bài tập',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
