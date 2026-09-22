import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import 'main/main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error(context) : AppTheme.prim(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
      remember: _rememberMe,
    );

    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _loginAsGuest() {
    context.read<AuthProvider>().continueAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _comingSoon(String provider) {
    _showMessage('เข้าสู่ระบบด้วย $provider ยังไม่รองรับในขณะนี้', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final form = _LoginForm(
              emailController: _emailController,
              passwordController: _passwordController,
              rememberMe: _rememberMe,
              onRememberChanged: (v) => setState(() => _rememberMe = v),
              isLoading: auth.isLoading,
              onSubmit: _login,
              onGuest: _loginAsGuest,
              onSocial: _comingSoon,
            );

            if (isWide) {
              return Row(
                children: [
                  const Expanded(flex: 5, child: LoginBrandPanel(wide: true)),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginBrandPanel(wide: false),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                    child: form,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// แผงแบรนด์ไล่สีที่ใช้ร่วมกันระหว่างหน้า login และ register
class LoginBrandPanel extends StatelessWidget {
  final bool wide;
  final String title;
  final String subtitle;

  const LoginBrandPanel({
    super.key,
    required this.wide,
    this.title = 'สูตรอาหาร',
    this.subtitle = 'บันทึก แบ่งปัน และค้นพบสูตรอาหารที่คุณรัก',
  });

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.prim(context);
    return Container(
      height: wide ? double.infinity : 240,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.4)!],
        ),
        borderRadius: wide ? null : const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Center(child: Text('🍳', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(title, style: AppTypography.display(color: Colors.white).copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGuest;
  final ValueChanged<String> onSocial;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.onGuest,
    required this.onSocial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ยินดีต้อนรับกลับ', style: AppTypography.display(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('ยังไม่มีบัญชี? ', style: AppTypography.body(color: AppTheme.txtSecondary(context))),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: Text('สมัครสมาชิก', style: AppTypography.bodyStrong(color: AppTheme.prim(context))),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'อีเมล',
          controller: emailController,
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'รหัสผ่าน',
          controller: passwordController,
          hint: '••••••••',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: rememberMe,
                onChanged: (v) => onRememberChanged(v ?? true),
                activeColor: AppTheme.prim(context),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => onRememberChanged(!rememberMe),
              child: Text('จดจำฉันไว้', style: AppTypography.body(color: AppTheme.txtSecondary(context))),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('ลืมรหัสผ่าน?'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(label: 'เข้าสู่ระบบ', onPressed: onSubmit, loading: isLoading),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.div(context))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('หรือ', style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
            ),
            Expanded(child: Divider(color: AppTheme.div(context))),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SocialLoginButton(
          label: 'ดำเนินการต่อด้วย Google',
          onTap: () => onSocial('Google'),
          badge: const GoogleBadge(),
        ),
        const SizedBox(height: AppSpacing.md),
        SocialLoginButton(
          label: 'ดำเนินการต่อด้วย GitHub',
          onTap: () => onSocial('GitHub'),
          badge: Icon(Icons.code_rounded, size: 18, color: AppTheme.txtPrimary(context)),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.outline(label: 'ดูสูตรอาหารโดยไม่เข้าสู่ระบบ', onPressed: onGuest),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// ปุ่มล็อกอินโซเชียลแบบ placeholder — ใช้ร่วมกันระหว่างหน้า login และ register
class SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget badge;
  final VoidCallback onTap;

  const SocialLoginButton({super.key, required this.label, required this.badge, required this.onTap});

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
              Text(label, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 14)),
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
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
      child: const Text(
        'G',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
      ),
    );
  }
}
