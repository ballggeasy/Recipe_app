import 'dart:async';

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
import '../widgets/google_sign_in_section.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// ความกว้างสูงสุดของฟอร์มล็อกอิน/สมัครสมาชิก ปุ่มทุกปุ่มจึงกว้างเท่ากัน
/// (ปุ่ม Google ที่ Google วาดเองบนเว็บกว้างได้สูงสุด 400 px)
const kAuthFormMaxWidth = 400.0;

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
        backgroundColor: isError
            ? AppTheme.error(context)
            : AppTheme.prim(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
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
    // AuthGate สลับไป MainScreen เอง — ห้าม push ทับ ไม่เช่นนั้น state ต่อบัญชีจะไม่รีเฟรช
  }

  void _loginAsGuest() {
    context.read<AuthProvider>().continueAsGuest();
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
              onMessage: _showMessage,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.xl,
                          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xl,
                    ),
                    // ฟอร์มกว้างไม่เกิน kAuthFormMaxWidth ตรงกลางจอ (ปุ่ม Google บนเว็บกว้างได้สูงสุดเท่านี้)
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: kAuthFormMaxWidth,
                        ),
                        child: form,
                      ),
                    ),
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
class LoginBrandPanel extends StatefulWidget {
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
  State<LoginBrandPanel> createState() => _LoginBrandPanelState();
}

class _LoginBrandPanelState extends State<LoginBrandPanel> {
  static const _images = [
    'assets/images/recipes/tom_yum_kung.jpg',
    'assets/images/recipes/som_tum.jpg',
    'assets/images/recipes/pad_krapao.jpg',
    'assets/images/recipes/bibimbap.png',
    'assets/images/recipes/shoyu_ramen.jpg',
    'assets/images/recipes/pizza_margherita.jpg',
    'assets/images/recipes/carbonara.jpg',
    'assets/images/recipes/korean_fried_chicken.jpg',
    'assets/images/recipes/kimchi_jjigae.jpg',
    'assets/images/recipes/salmon_don.png',
    'assets/images/recipes/takoyaki.png',
    'assets/images/recipes/steamed_dumplings.jpg',
    'assets/images/recipes/sweet_and_sour_pork.jpg',
    'assets/images/recipes/tteokbokki.jpg',
    'assets/images/recipes/salted_egg_fried_rice.png',
    'assets/images/recipes/tiramisu.png',
  ];

  late final PageController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_controller.page ?? 0).round() + 1;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.prim(context);
    return Container(
      height: widget.wide ? double.infinity : 240,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: widget.wide
            ? null
            : const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.xxl),
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemBuilder: (context, index) {
              final path = _images[index % _images.length];
              return Image.asset(
                path,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base.withValues(alpha: 0.82),
                  Color.lerp(base, Colors.black, 0.55)!.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Center(
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
                  child: const Center(
                    child: Text('🍳', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  widget.title,
                  style: AppTypography.display(color: Colors.white).copyWith(
                    fontSize: 26,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.body(
                          color: Colors.white.withValues(alpha: 0.9),
                        ).copyWith(
                          shadows: const [
                            Shadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final ValueChanged<String> onMessage;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.onGuest,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ยินดีต้อนรับกลับ',
          style: AppTypography.display(
            color: AppTheme.txtPrimary(context),
          ).copyWith(fontSize: 24),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'ยังไม่มีบัญชี? ',
              style: AppTypography.body(color: AppTheme.txtSecondary(context)),
            ),
            TapTarget(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: Text(
                'สมัครสมาชิก',
                style: AppTypography.bodyStrong(color: AppTheme.prim(context)),
              ),
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
            // checkbox กับข้อความรวมเป็นตัวควบคุมเดียว: กดตรงไหนของแถวก็สลับได้ และ screen reader อ่านเป็น "จดจำฉันไว้, checkbox"
            MergeSemantics(
              child: InkWell(
                onTap: () => onRememberChanged(!rememberMe),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kMinInteractiveDimension,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: (v) => onRememberChanged(v ?? true),
                          activeColor: AppTheme.prim(context),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'จดจำฉันไว้',
                        style: AppTypography.body(
                          color: AppTheme.txtSecondary(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('ลืมรหัสผ่าน?'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          label: 'เข้าสู่ระบบ',
          onPressed: onSubmit,
          loading: isLoading,
        ),
        GoogleSignInSection(onMessage: onMessage),
        const SizedBox(height: AppSpacing.xl),
        AppButton.outline(
          label: 'ดูสูตรอาหารโดยไม่เข้าสู่ระบบ',
          onPressed: onGuest,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
