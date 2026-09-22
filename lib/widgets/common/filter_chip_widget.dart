import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

/// ชิปตัวกรอง/หมวดหมู่ — ใช้ทั้งเป็นชิปหมวดหมู่แบบทึบ และชิปตัวกรองแบบมีเส้นขอบ
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.filled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = filled ? AppTheme.prim(context) : AppTheme.primLight(context);
    final selectedFg = filled ? Colors.white : AppTheme.prim(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? selectedBg : AppTheme.div(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: isSelected ? selectedFg : AppTheme.txtSecondary(context)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.caption(
                  color: isSelected ? selectedFg : AppTheme.txtPrimary(context),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
