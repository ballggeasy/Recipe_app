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

/// ความสูงตายตัวของปุ่มที่ Google วาดบนเว็บ
const _googleButtonHeight = 40.0;

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
      // Google ไม่ให้ทำปุ่มเอง (สูง 40 กว้าง 200–400) จึงวาดปุ่มของเราให้เหมือนปุ่มอื่น (สูง 52 เต็มความกว้าง)
      // แล้ววางปุ่มของ Google แบบโปร่งใสทับไว้ให้ขยายเต็มพื้นที่ ผู้ใช้กดโดนปุ่มจริงของ Google
      // (เปิดหน้าเลือกบัญชีและส่ง ID token กลับมาทาง stream) ส่วนที่เห็นคือปุ่มของเรา
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(200.0, 400.0);
          return Center(
            child: SizedBox(
              width: width,
              height: GoogleSignInFace.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(child: GoogleSignInFace(onTap: () {})),
                  // ปุ่มของ Google สูง 40 อยู่กลางปุ่มของเรา (เหลือขอบบนล่างข้างละ 6 ที่กดไม่โดน)
                  // ไม่ยืดด้วย Transform เพราะ iframe ของ Google ที่ถูกขยายไม่ยืนยันว่ารับการกดได้ทั้งพื้นที่
                  Center(
                    child: Opacity(
                      opacity: 0.01,
                      child: SizedBox(
                        height: _googleButtonHeight,
                        child: service.buildGoogleButton(
                          width: width,
                          dark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return GoogleSignInFace(onTap: _signIn, loading: _busy);
  }
}
