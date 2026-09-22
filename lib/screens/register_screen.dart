import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error(context),
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
      _showError('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }
    if (!email.contains('@')) {
      _showError('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }
    if (password.length < 6) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }
    if (password != confirm) {
      _showError('รหัสผ่านทั้งสองช่องไม่ตรงกัน');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.register(name: name, email: email, password: password);

    if (!mounted) return;
    if (error != null) {
      _showError(error);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'ชื่อ',
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                hint: 'ชื่อที่แสดงในแอป',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'อีเมล',
                controller: _emailController,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                hint: 'example@email.com',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'รหัสผ่าน',
                controller: _passwordController,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                hint: 'อย่างน้อย 6 ตัวอักษร',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'ยืนยันรหัสผ่าน',
                controller: _confirmController,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                hint: '••••••••',
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton.primary(label: 'สมัครสมาชิก', onPressed: _register, loading: auth.isLoading),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
