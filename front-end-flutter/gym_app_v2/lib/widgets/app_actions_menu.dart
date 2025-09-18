import 'package:flutter/material.dart';

/// Generic 3-dots popup actions menu to unify styling across Plan / Day / Exercise.
///
/// Features:
/// - Configurable list of actions with icon, label, semantic value.
/// - Optional loading (busy) state replacing the menu button.
/// - Optional divider insertion.
/// - Shared styling: dark surface, rounded corners, subtle border & shadow.
class AppActionsMenu<T extends Object> extends StatelessWidget {
  final List<AppActionItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool isBusy;
  final String? tooltip;
  final Color? backgroundColor;
  final double iconSize;
  final EdgeInsets iconPadding;
  final Color? overlayColor;

  const AppActionsMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.isBusy = false,
    this.tooltip,
    this.backgroundColor,
    this.iconSize = 18,
    this.iconPadding = const EdgeInsets.all(6),
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return _buildBusy();
    }
    return PopupMenuButton<T>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      color: backgroundColor ?? const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.4),
      icon: _buildIconButton(context),
      onSelected: onSelected,
      itemBuilder: (ctx) => _buildEntries(),
    );
  }

  List<PopupMenuEntry<T>> _buildEntries() {
    final List<PopupMenuEntry<T>> entries = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.isDivider) {
        entries.add(const PopupMenuDivider(height: 4));
      } else {
        entries.add(
          PopupMenuItem<T>(
            value: item.value!,
            child: Row(
              children: [
                if (item.icon != null)
                  Icon(item.icon, size: 18, color: item.color ?? Colors.white),
                if (item.icon != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: item.color ?? Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return entries;
  }

  Widget _buildIconButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      padding: iconPadding,
      child: Icon(Icons.more_vert, color: Colors.white, size: iconSize),
    );
  }

  Widget _buildBusy() {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
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
}

class AppActionItem<T extends Object> {
  final T? value; // null when this is a divider
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isDivider;

  const AppActionItem.action({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  }) : isDivider = false;

  const AppActionItem.divider()
    : value = null,
      label = '',
      icon = null,
      color = null,
      isDivider = true;
}
