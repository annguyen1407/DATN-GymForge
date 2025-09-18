import 'package:flutter/material.dart';

enum PlanAction { edit, delete }

typedef PlanActionCallback = Future<void> Function(PlanAction action);

/// 3-dots menu for Plan actions (edit/delete) reusing styling similar to DayActionsMenu.
class PlanActionsMenu extends StatelessWidget {
  final PlanActionCallback onAction;
  final Color? backgroundColor;
  const PlanActionsMenu({
    super.key,
    required this.onAction,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlanAction>(
      tooltip: 'Tùy chọn kế hoạch',
      padding: EdgeInsets.zero,
      color: backgroundColor ?? const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.4),
      icon: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
      ),
      onSelected: (action) => onAction(action),
      itemBuilder: (ctx) => [
        _buildItem(
          icon: Icons.edit,
          title: 'Chỉnh sửa',
          action: PlanAction.edit,
          color: Colors.white,
        ),
        const PopupMenuDivider(height: 4),
        _buildItem(
          icon: Icons.delete_forever,
          title: 'Xoá',
          action: PlanAction.delete,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  PopupMenuEntry<PlanAction> _buildItem({
    required IconData icon,
    required String title,
    required PlanAction action,
    required Color color,
  }) {
    return PopupMenuItem<PlanAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
