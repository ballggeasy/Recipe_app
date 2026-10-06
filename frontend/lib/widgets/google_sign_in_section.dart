import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'social_login_button.dart';

/// เส้นคั่น "หรือ" + ปุ่มเข้าสู่ระบบด้วย Google สำหรับหน้า login
/// ไม่แสดงอะไรเลยถ้าแอปนี้ไม่มี Google client ID (กดแล้วก็ล็อกอินไม่ได้อยู่ดี)
class GoogleSignInSection extends StatelessWidget {
  /// ข้อความที่ต้องแจ้งผู้ใช้ (เช่น ล็อกอินไม่สำเร็จ) — หน้าจอเป็นคนเลือกวิธีแสดง
  final void Function(String message) onMessage;

  const GoogleSignInSection({super.key, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    if (!context.read<AuthProvider>().googleSignIn.isConfigured) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.div(context))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'หรือ',
                style: AppTypography.caption(
                  color: AppTheme.txtSecondary(context),
                ),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.div(context))),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GoogleSignInButton(onMessage: onMessage),
      ],
    );
  }
}

/// ปุ่ม "ดำเนินการต่อด้วย Google"
/// - มือถือ: ปุ่มของแอป กดแล้วเปิดหน้าเลือกบัญชี Google
/// - เว็บ: ปุ่มที่ Google วาดเอง (Google ไม่อนุญาตให้ทำเอง) แล้วรับ ID token ทาง stream
/// ล็อกอินสำเร็จแล้ว AuthGate สลับไปหน้าหลักเอง จึงไม่ต้อง navigate ที่นี่
class GoogleSignInButton extends StatefulWidget {
  final void Function(String message) onMessage;

  const GoogleSignInButton({super.key, required this.onMessage});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<String>? _tokens;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final service = context.read<AuthProvider>().googleSignIn;
    if (service.isConfigured && service.usesGoogleButton) {
      _tokens = service.idTokens.listen(_loginWithToken);
    }
  }

  @override
  void dispose() {
    _tokens?.cancel();
    super.dispose();
  }

  Future<void> _loginWithToken(String idToken) async {
    final error = await context.read<AuthProvider>().loginWithGoogle(idToken);
    if (mounted && error != null) widget.onMessage(error);
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) widget.onMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<AuthProvider>().googleSignIn;
    if (!service.isConfigured) return const SizedBox.shrink();

    if (service.usesGoogleButton) {
      return Center(child: service.buildGoogleButton());
    }
    return SocialLoginButton(
      label: 'ดำเนินการต่อด้วย Google',
      onTap: _signIn,
      badge: const GoogleBadge(),
    );
  }
}
