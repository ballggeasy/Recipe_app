import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// แสดงดาวคะแนนเฉลี่ยพร้อมจำนวนรีวิว เช่น "4.5 ★ · 128 รีวิว"
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double fontSize;
  final double starSize;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.fontSize = 12,
    this.starSize = 14,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: starSize, color: AppTheme.star(context)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)).copyWith(fontSize: fontSize),
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '· $reviewCount รีวิว',
            style: AppTypography.caption(color: AppTheme.txtSecondary(context)).copyWith(fontSize: fontSize),
          ),
        ],
      ],
    );
  }
}
