import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _emailVerified = false;
  bool _isChecking = false;
  bool _isSaving = false;

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

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('กรุณากรอกอีเมลที่ถูกต้อง');
      return;
    }

    setState(() => _isChecking = true);
    final exists = await context.read<AuthProvider>().checkUserExists(email);
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _emailVerified = exists;
    });

    if (!exists) {
      _showMessage('ไม่พบบัญชีที่ใช้อีเมลนี้');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.length < 6) {
      _showMessage('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    setState(() => _isSaving = true);
    final error = await context.read<AuthProvider>().resetPassword(
          email: _emailController.text.trim(),
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage('ตั้งรหัสผ่านใหม่สำเร็จ กรุณาเข้าสู่ระบบอีกครั้ง', isError: false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ระบบนี้ทำงานแบบ local บนเครื่องเท่านั้น จึงไม่มีการส่งอีเมลยืนยันจริง '
                'กรอกอีเมลของบัญชีเพื่อรีเซ็ตรหัสผ่านได้โดยตรง',
                style: AppTypography.body(color: AppTheme.txtSecondary(context)),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'อีเมล',
                controller: _emailController,
                enabled: !_emailVerified,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                hint: 'example@email.com',
              ),
              if (!_emailVerified) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(label: 'ตรวจสอบอีเมล', onPressed: _checkEmail, loading: _isChecking),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'รหัสผ่านใหม่',
                  controller: _newPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  hint: '••••••••',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(label: 'ตั้งรหัสผ่านใหม่', onPressed: _resetPassword, loading: _isSaving),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
