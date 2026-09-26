import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/tap_target.dart';
import 'login_screen.dart';
import 'main/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }
    if (!email.contains('@')) {
      _showMessage('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }
    if (password.length < 6) {
      _showMessage('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }
    if (password != confirm) {
      _showMessage('รหัสผ่านทั้งสองช่องไม่ตรงกัน');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.register(name: name, email: email, password: password);

    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void _comingSoon(String provider) {
    _showMessage('สมัครสมาชิกด้วย $provider ยังไม่รองรับในขณะนี้', isError: false);
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
            final form = _RegisterForm(
              nameController: _nameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmController: _confirmController,
              isLoading: auth.isLoading,
              onSubmit: _register,
              onSocial: _comingSoon,
            );

            if (isWide) {
              return Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: LoginBrandPanel(
                      wide: true,
                      title: 'สร้างบัญชีใหม่',
                      subtitle: 'เริ่มต้นบันทึกและแบ่งปันสูตรอาหารที่คุณรัก',
                    ),
                  ),
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
                  const LoginBrandPanel(
                    wide: false,
                    title: 'สร้างบัญชีใหม่',
                    subtitle: 'เริ่มต้นบันทึกและแบ่งปันสูตรอาหารที่คุณรัก',
                  ),
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

class _RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSocial;

  const _RegisterForm({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.isLoading,
    required this.onSubmit,
    required this.onSocial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('สมัครสมาชิก', style: AppTypography.display(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('มีบัญชีอยู่แล้ว? ', style: AppTypography.body(color: AppTheme.txtSecondary(context))),
            TapTarget(
              onTap: () => Navigator.pop(context),
              child: Text('เข้าสู่ระบบ', style: AppTypography.bodyStrong(color: AppTheme.prim(context))),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'ชื่อ',
          controller: nameController,
          hint: 'ชื่อที่แสดงในแอป',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
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
          hint: 'อย่างน้อย 6 ตัวอักษร',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'ยืนยันรหัสผ่าน',
          controller: confirmController,
          hint: '••••••••',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(label: 'สมัครสมาชิก', onPressed: onSubmit, loading: isLoading),
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
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
