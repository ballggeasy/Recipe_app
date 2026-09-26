import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

/// ช่องกรอกข้อความมาตรฐานของแอป พร้อม label, icon และปุ่มซ่อน/แสดงรหัสผ่านในตัว
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      validator: widget.validator,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onSubmitted,
      style: AppTypography.body(color: AppTheme.txtPrimary(context)),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: AppTheme.surf(context),
        alignLabelWithHint: widget.maxLines > 1,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20, color: AppTheme.txtSecondary(context))
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.txtSecondary(context),
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppTheme.div(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppTheme.div(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppTheme.prim(context), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 16),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label!, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }
}
