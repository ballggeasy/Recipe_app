import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import 'tap_target.dart';

/// หัวข้อของแต่ละ section พร้อมปุ่ม "ดูทั้งหมด" หรือ widget อื่นด้านขวา (ถ้ามี)
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.h2(color: AppTheme.txtPrimary(context)),
          ),
        ),
        ?trailing,
        if (trailing == null && actionLabel != null)
          TapTarget(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTypography.bodyStrong(color: AppTheme.prim(context)),
            ),
          ),
      ],
    );
  }
}
