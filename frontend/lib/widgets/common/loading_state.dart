import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

/// สถานะกำลังโหลด ใช้แทน CircularProgressIndicator เปล่า ๆ เพื่อความรู้สึกที่ตั้งใจออกแบบ
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2.6, color: AppTheme.prim(context)),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.base),
            Text(
              message!,
              style: AppTypography.body(color: AppTheme.txtSecondary(context)),
            ),
          ],
        ],
      ),
    );
  }
}
