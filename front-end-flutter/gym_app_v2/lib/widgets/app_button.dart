import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Unified reusable button system for the app's dark + purple accent theme.
///
/// Goals:
/// - Consistent spacing, typography, hit areas
/// - Centralized color + elevation logic (incl. pressed/disabled/gradient)
/// - Variants mapping to semantic intent (primary, secondary, danger, outline, text, subtle, gradient)
/// - Built-in loading state & icon slots
/// - Minimal boilerplate replacement for ElevatedButton/TextButton/etc.
///
/// Usage:
/// AppButton.primary(label: 'Lưu', onPressed: saveFn)
/// AppButton.danger(label: 'Xoá', loading: isDeleting, onPressed: deleteFn)
/// AppButton.gradient(label: 'Bắt đầu', leadingIcon: Icons.play_arrow, onPressed: start)
///
/// Variants:
/// - primary: Solid purple accent with shadow. Main CTAs.
/// - secondary: Dark surface subtle elevation. Secondary emphasis.
/// - outline: Bordered low-emphasis action on dark surfaces.
/// - text: Minimal inline action (no background) – NOT fullWidth by default.
/// - danger: Destructive (red) actions (delete, reset).
/// - gradient: Large hero / prominent CTA using brand gradient.
/// - subtle: Ultra-low emphasis, blends into background.
///
/// Sizes:
/// - small: Compact chips / inline toolbars.
/// - medium: Default form actions.
/// - large: Bottom bars / primary flows / wide CTAs.
///
/// Disabled state logic:
/// - Automatically disabled when onPressed is null or loading = true.
/// - Visual opacity + removal of shadows & ripples.
///
/// Loading behavior:
/// - Spinner replaces leading icon & text color remains consistent.
/// - Label still rendered (unless replaced manually) for layout stability.
///
/// Accessibility:
/// - Semantics button wrapper with enabled flag & label propagation.
///
/// Future enhancements (if needed):
/// - Support for expanded vertical layout (icon above text)
/// - Built-in badge / notification dot
/// - Icon-only variant convenience
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool fullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool enabled;
  final double? cornerRadius;
  final Color? overrideColor;
  final EdgeInsets? padding;
  final Duration animationDuration;

  const AppButton._internal({
    required this.label,
    required this.onPressed,
    required this.variant,
    required this.size,
    required this.loading,
    required this.fullWidth,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.enabled,
    required this.cornerRadius,
    required this.overrideColor,
    required this.padding,
    required this.animationDuration,
    Key? key,
  }) : super(key: key);

  // Factory conveniences
  factory AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    bool fullWidth = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.primary,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 170),
  );
  factory AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    bool fullWidth = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.secondary,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 170),
  );
  factory AppButton.outline({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    bool fullWidth = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.outline,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 170),
  );
  factory AppButton.text({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.text,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 140),
  );
  factory AppButton.danger({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    bool fullWidth = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.danger,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 170),
  );
  factory AppButton.gradient({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.large,
    bool loading = false,
    bool fullWidth = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.gradient,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 190),
  );
  factory AppButton.subtle({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    bool fullWidth = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => AppButton._internal(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.subtle,
    size: size,
    loading: loading,
    fullWidth: fullWidth,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    enabled: onPressed != null && !loading,
    cornerRadius: null,
    overrideColor: null,
    padding: null,
    animationDuration: const Duration(milliseconds: 160),
  );

  @override
  Widget build(BuildContext context) {
    final spec = _ButtonSpec.forVariant(variant, size, overrideColor);
    final cr = cornerRadius ?? spec.radius;
    final isDisabled = !enabled;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          SizedBox(
            width: spec.loaderSize,
            height: spec.loaderSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                spec.fgDisabled ?? spec.fg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (leadingIcon != null) ...[
          Icon(
            leadingIcon,
            size: spec.iconSize,
            color: isDisabled ? spec.fgDisabled : spec.fg,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: spec.textStyle.copyWith(
              color: isDisabled ? spec.fgDisabled : spec.fg,
            ),
          ),
        ),
        if (!loading && trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(
            trailingIcon,
            size: spec.iconSize,
            color: isDisabled ? spec.fgDisabled : spec.fg,
          ),
        ],
      ],
    );

    final resolvedPadding = padding ?? spec.padding;

    Widget buttonCore = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isDisabled ? 0.55 : 1,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeOut,
        padding: resolvedPadding,
        decoration: _buildDecoration(spec, cr, isDisabled),
        child: child,
      ),
    );

    if (!isDisabled) {
      buttonCore = _InteractiveScale(child: buttonCore);
    }

    final wrapped = fullWidth
        ? SizedBox(width: double.infinity, child: buttonCore)
        : buttonCore;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: label,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(cr),
        splashColor: spec.splashColor,
        highlightColor: Colors.transparent,
        child: wrapped,
      ),
    );
  }

  BoxDecoration _buildDecoration(
    _ButtonSpec spec,
    double radius,
    bool disabled,
  ) {
    if (spec.gradient != null) {
      return BoxDecoration(
        gradient: disabled
            ? spec.disabledGradient ?? spec.gradient
            : spec.gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: disabled ? [] : spec.shadows,
        border: spec.border,
      );
    }
    return BoxDecoration(
      color: disabled ? spec.bgDisabled : spec.bg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: disabled ? [] : spec.shadows,
      border: spec.border,
    );
  }
}

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
  gradient,
  subtle,
}

enum AppButtonSize { small, medium, large }

class _ButtonSpec {
  final Color? bg;
  final Color? bgDisabled;
  final Color fg;
  final Color? fgDisabled;
  final Gradient? gradient;
  final Gradient? disabledGradient;
  final List<BoxShadow>? shadows;
  final Border? border;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double radius;
  final double iconSize;
  final double loaderSize;
  final Color? splashColor;

  _ButtonSpec({
    required this.bg,
    required this.bgDisabled,
    required this.fg,
    required this.fgDisabled,
    required this.gradient,
    required this.disabledGradient,
    required this.shadows,
    required this.border,
    required this.padding,
    required this.textStyle,
    required this.radius,
    required this.iconSize,
    required this.loaderSize,
    required this.splashColor,
  });

  static _ButtonSpec forVariant(
    AppButtonVariant v,
    AppButtonSize size,
    Color? overrideColor,
  ) {
    // Base palette from tokens
    const accent = DesignTokens.brand;
    const accentAlt = DesignTokens.brandGradientEnd;
    const danger = DesignTokens.danger; // align with global semantic
    const surfaceDark = DesignTokens.surface; // closest mapping
    const surfaceDarker = DesignTokens.surfaceAlt; // deeper layer
    final outlineColor = DesignTokens.surfaceOutline.withOpacity(0.55);

    double heightPad(AppButtonSize s) {
      switch (s) {
        case AppButtonSize.small:
          return 10;
        case AppButtonSize.medium:
          return 14;
        case AppButtonSize.large:
          return 18;
      }
    }

    double horizPad(AppButtonSize s) {
      switch (s) {
        case AppButtonSize.small:
          return 14;
        case AppButtonSize.medium:
          return 20;
        case AppButtonSize.large:
          return 24;
      }
    }

    final padding = EdgeInsets.symmetric(
      vertical: heightPad(size),
      horizontal: horizPad(size),
    );

    TextStyle baseText(AppButtonSize s) {
      switch (s) {
        case AppButtonSize.small:
          return const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          );
        case AppButtonSize.medium:
          return const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: .25,
          );
        case AppButtonSize.large:
          return const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          );
      }
    }

    double iconSize(AppButtonSize s) {
      switch (s) {
        case AppButtonSize.small:
          return 16;
        case AppButtonSize.medium:
          return 20;
        case AppButtonSize.large:
          return 22;
      }
    }

    double loaderSize(AppButtonSize s) {
      switch (s) {
        case AppButtonSize.small:
          return 16;
        case AppButtonSize.medium:
          return 20;
        case AppButtonSize.large:
          return 22;
      }
    }

    final radius = () {
      switch (size) {
        case AppButtonSize.small:
          return 14.0;
        case AppButtonSize.medium:
          return 18.0;
        case AppButtonSize.large:
          return 20.0;
      }
    }();

    // Defaults
    Color fg = Colors.white;
    Color? fgDisabled = Colors.white.withOpacity(0.45);
    Color? bg;
    Color? bgDisabled;
    Gradient? gradient;
    Gradient? disabledGradient;
    List<BoxShadow>? shadows;
    Border? border;
    Color? splashColor = Colors.white.withOpacity(0.08);

    switch (v) {
      case AppButtonVariant.primary:
        bg = overrideColor ?? accent;
        bgDisabled = surfaceDark;
        shadows = [
          BoxShadow(
            color: (overrideColor ?? accent).withOpacity(0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case AppButtonVariant.secondary:
        bg = surfaceDark;
        bgDisabled = surfaceDarker;
        fg = Colors.white.withOpacity(0.9);
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case AppButtonVariant.outline:
        bg = surfaceDarker;
        bgDisabled = surfaceDarker.withOpacity(0.8);
        fg = Colors.white.withOpacity(0.9);
        border = Border.all(color: outlineColor, width: 1);
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        bgDisabled = Colors.transparent;
        fg = overrideColor ?? accent;
        splashColor = (overrideColor ?? accent).withOpacity(.15);
        break;
      case AppButtonVariant.danger:
        bg = danger;
        bgDisabled = danger.withOpacity(.5);
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: danger.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case AppButtonVariant.gradient:
        gradient = const LinearGradient(
          colors: [
            DesignTokens.brandGradientStart,
            DesignTokens.brandGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        disabledGradient = LinearGradient(
          colors: [
            DesignTokens.brandGradientStart.withOpacity(.4),
            DesignTokens.brandGradientEnd.withOpacity(.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: accentAlt.withOpacity(0.35),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ];
        break;
      case AppButtonVariant.subtle:
        bg = Colors.white.withOpacity(0.06);
        bgDisabled = Colors.white.withOpacity(0.04);
        fg = Colors.white.withOpacity(0.85);
        border = Border.all(color: Colors.white.withOpacity(0.08), width: 1);
        break;
    }

    return _ButtonSpec(
      bg: bg,
      bgDisabled: bgDisabled ?? bg?.withOpacity(.55),
      fg: fg,
      fgDisabled: fgDisabled,
      gradient: gradient,
      disabledGradient: disabledGradient,
      shadows: shadows,
      border: border,
      padding: padding,
      textStyle: baseText(size),
      radius: radius,
      iconSize: iconSize(size),
      loaderSize: loaderSize(size),
      splashColor: splashColor,
    );
  }
}

class _InteractiveScale extends StatefulWidget {
  final Widget child;
  const _InteractiveScale({required this.child});
  @override
  State<_InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<_InteractiveScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: .08,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  void _press() {
    _controller.forward();
  }

  void _release() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final scale = 1 - _anim.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
