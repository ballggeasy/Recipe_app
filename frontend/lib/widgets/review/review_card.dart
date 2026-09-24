import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../rating_display.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onReport;
  final VoidCallback? onReply;

  const ReviewCard({
    super.key,
    required this.review,
    this.isLiked = false,
    this.onLike,
    this.onReport,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surf(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.div(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primLight(context),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: AppTypography.bodyStrong(color: AppTheme.prim(context)).copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 13.5),
                    ),
                    RatingDisplay(
                      rating: review.rating,
                      reviewCount: 0,
                      fontSize: 11,
                      starSize: 12,
                      showCount: false,
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.caption(color: AppTheme.txtSecondary(context)).copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.content, style: AppTypography.body(color: AppTheme.txtPrimary(context))),
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: AppTheme.primLight(context),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.image_outlined, color: AppTheme.prim(context)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionButton(
                icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                label: '${review.likeCount}',
                onTap: onLike,
                active: isLiked,
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.reply_outlined,
                label: 'ตอบกลับ',
                onTap: onReply,
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.flag_outlined,
                label: review.isReported ? 'รายงานแล้ว' : 'รายงาน',
                onTap: review.isReported ? null : onReport,
              ),
            ],
          ),
          if (review.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...review.replies.map(
              (r) => Padding(
                padding: const EdgeInsets.only(left: 20, top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: AppTheme.txtSecondary(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.body(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 13),
                          children: [
                            TextSpan(
                              text: '${r.userName}: ',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: r.content),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.prim(context) : AppTheme.txtSecondary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.caption(color: color)),
          ],
        ),
      ),
    );
  }
}
