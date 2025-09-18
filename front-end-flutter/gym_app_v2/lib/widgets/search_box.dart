import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

enum SearchBoxVariant { filled, elevated, outlined }

class SearchBox extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hint;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double height;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? hintColor;
  final SearchBoxVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final bool showClear;
  final Duration animationDuration;

  const SearchBox({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hint = 'Tìm kiếm...',
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.borderRadius = 16,
    this.height = 48,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.hintColor,
    this.variant = SearchBoxVariant.filled,
    this.leading,
    this.trailing,
    this.showClear = true,
    this.animationDuration = const Duration(milliseconds: 140),
  });

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgBase = widget.backgroundColor ?? DesignTokens.surfaceAlt;
    final ic = widget.iconColor ?? DesignTokens.textSecondary;
    final tc = widget.textColor ?? DesignTokens.textPrimary;
    final hc = widget.hintColor ?? DesignTokens.textSecondary;
    final bg = _focused
        ? (widget.variant == SearchBoxVariant.filled
              ? DesignTokens.surface
              : bgBase)
        : bgBase;

    BoxDecoration decoration;
    switch (widget.variant) {
      case SearchBoxVariant.elevated:
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_focused ? 0.7 : 0.5),
              blurRadius: _focused ? 10 : 6,
              offset: Offset(0, _focused ? 4 : 3),
            ),
          ],
        );
        break;
      case SearchBoxVariant.outlined:
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _focused
                ? DesignTokens.brand
                : DesignTokens.surfaceOutline.withOpacity(.35),
            width: 1.2,
          ),
        );
        break;
      case SearchBoxVariant.filled:
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        );
    }

    final showClear = widget.showClear && widget.controller.text.isNotEmpty;

    return Padding(
      padding: widget.padding,
      child: AnimatedContainer(
        duration: widget.animationDuration,
        curve: Curves.easeOut,
        height: widget.height,
        decoration: decoration,
        child: Row(
          children: [
            const SizedBox(width: 6),
            widget.leading ?? Icon(Icons.search, color: ic),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                style: TextStyle(color: tc, height: 1.25),
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: hc),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              widget.trailing!,
              const SizedBox(width: 4),
            ],
            if (showClear)
              IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged?.call('');
                  widget.onClear?.call();
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                },
                icon: Icon(Icons.close, color: ic, size: 18),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
