import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize { medium, small }

/// ปุ่มมาตรฐานของแอป — ใช้แทน ElevatedButton/OutlinedButton แบบ ad-hoc ทั่วทั้งแอป
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.danger;

  double get _height => size == AppButtonSize.small ? 42 : 52;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    final colors = _colorsFor(context);

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.foreground),
                const SizedBox(width: 8),
              ],
              _label(colors.foreground),
            ],
          );

    final buttonCore = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: _height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: isDisabled ? colors.background.withValues(alpha: 0.55) : colors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: colors.border != null ? Border.all(color: colors.border!) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: isDisabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(child: child),
          ),
        ),
      ),
    );

    return fullWidth ? buttonCore : IntrinsicWidth(child: buttonCore);
  }

  Widget _label(Color color) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.button(color: color).copyWith(fontSize: size == AppButtonSize.small ? 13.5 : 15),
    );
    // Row gives unbounded main-axis space to non-flex children, so a long label
    // needs Flexible to wrap/ellipsize instead of overflowing. Skipped when the
    // button hugs its content (fullWidth: false), since that path is wrapped in
    // IntrinsicWidth, which cannot size a Flexible/Expanded child.
    return fullWidth ? Flexible(child: text) : text;
  }

  _ButtonColors _colorsFor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(background: AppTheme.prim(context), foreground: Colors.white);
      case AppButtonVariant.secondary:
        return _ButtonColors(background: AppTheme.secondary(context), foreground: Colors.white);
      case AppButtonVariant.outline:
        return _ButtonColors(
          background: AppTheme.surf(context),
          foreground: AppTheme.txtPrimary(context),
          border: AppTheme.div(context),
        );
      case AppButtonVariant.ghost:
        return _ButtonColors(
          background: AppTheme.primLight(context),
          foreground: AppTheme.prim(context),
        );
      case AppButtonVariant.danger:
        return _ButtonColors(background: AppTheme.error(context), foreground: Colors.white);
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;

  const _ButtonColors({required this.background, required this.foreground, this.border});
}
