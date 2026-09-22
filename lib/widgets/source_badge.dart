import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// แสดง badge บอกแหล่งที่มาของสูตร: ทางการ (มี shield icon) หรือผู้ใช้อัปโหลด (มีชื่อผู้อัปโหลด)
class SourceBadge extends StatelessWidget {
  final Recipe recipe;
  final bool compact;

  const SourceBadge({super.key, required this.recipe, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isOfficial = recipe.isOfficial;
    final bgColor = isOfficial ? AppTheme.primLight(context) : AppTheme.secondaryMuted(context);
    final fgColor = isOfficial ? AppTheme.prim(context) : AppTheme.secondary(context);
    final icon = isOfficial ? Icons.verified_rounded : Icons.person_rounded;
    final label = isOfficial ? 'ทางการ' : (recipe.uploaderName ?? 'ผู้ใช้');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: fgColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.overline(color: fgColor)
                  .copyWith(fontSize: compact ? 10.5 : 12, letterSpacing: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
