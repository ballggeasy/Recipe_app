import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// ปุ่มล็อกอินโซเชียลหน้าตาเดียวกันทุกเจ้า — ใช้ร่วมกันระหว่างหน้า login และ register
class SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget badge;
  final VoidCallback onTap;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surf(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.div(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              badge,
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyStrong(
                  color: AppTheme.txtPrimary(context),
                ).copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleBadge extends StatelessWidget {
  const GoogleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4285F4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
