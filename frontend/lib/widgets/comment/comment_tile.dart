import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../uploaded_image.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final void Function(Comment comment)? onDelete;
  final String? currentUserId;
  final bool isNested;

  const CommentTile({
    super.key,
    required this.comment,
    this.onReply,
    this.onDelete,
    this.currentUserId,
    this.isNested = false,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete =
        onDelete != null &&
        currentUserId != null &&
        comment.userId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(left: isNested ? 24 : 0, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppTheme.primLight(context),
                child: Text(
                  comment.userName.isNotEmpty ? comment.userName[0] : '?',
                  style: AppTypography.bodyStrong(
                    color: AppTheme.prim(context),
                  ).copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: AppTypography.bodyStrong(
                            color: AppTheme.txtPrimary(context),
                          ).copyWith(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(comment.createdAt),
                          style: AppTypography.caption(
                            color: AppTheme.txtSecondary(context),
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildContent(context),
                    if (comment.imageUrl != null &&
                        comment.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      UploadedImage(url: comment.imageUrl!, size: 120),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _SmallButton(
                          icon: Icons.reply_outlined,
                          label: 'ตอบกลับ',
                          onTap: onReply,
                        ),
                        if (canDelete) ...[
                          const SizedBox(width: 12),
                          _SmallButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'ลบ',
                            onTap: () => onDelete!(comment),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (r) => CommentTile(
                comment: r,
                isNested: true,
                onReply: onReply,
                onDelete: onDelete,
                currentUserId: currentUserId,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final primary = AppTheme.txtPrimary(context);
    final accent = AppTheme.prim(context);
    if (comment.mentions.isEmpty) {
      return Text(
        comment.content,
        style: AppTypography.body(color: primary).copyWith(fontSize: 13.5),
      );
    }
    var text = comment.content;
    final spans = <InlineSpan>[];
    for (final mention in comment.mentions) {
      final tag = '@$mention';
      final idx = text.indexOf(tag);
      if (idx >= 0) {
        if (idx > 0) spans.add(TextSpan(text: text.substring(0, idx)));
        spans.add(
          TextSpan(
            text: tag,
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
        );
        text = text.substring(idx + tag.length);
      }
    }
    if (text.isNotEmpty) spans.add(TextSpan(text: text));
    return RichText(
      text: TextSpan(
        style: AppTypography.body(color: primary).copyWith(fontSize: 13.5),
        children: spans,
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SmallButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.txtSecondary(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption(
              color: AppTheme.txtSecondary(context),
            ).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
