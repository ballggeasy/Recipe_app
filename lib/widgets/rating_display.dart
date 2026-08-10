import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
        Icon(Icons.star_rounded, size: starSize, color: const Color(0xFFE0A33B)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimary(context),
          ),
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '· $reviewCount รีวิว',
            style: TextStyle(
              fontSize: fontSize,
              color: AppTheme.txtSecondary(context),
            ),
          ),
        ],
      ],
    );
  }
}
