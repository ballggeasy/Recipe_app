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
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeRequested = false;
  bool _isRequesting = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
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

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('กรุณากรอกอีเมลที่ถูกต้อง');
      return;
    }

    setState(() => _isRequesting = true);
    // backend ตอบเหมือนกันเสมอไม่ว่าจะมีบัญชีหรือไม่ จึงไปขั้นกรอกรหัสได้เลย
    final error = await context.read<AuthProvider>().requestPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _codeRequested = error == null;
    });

    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage('ถ้าอีเมลนี้มีบัญชี รหัสยืนยัน 6 หลักจะแสดงใน log ของ backend', isError: false);
    }
  }

  Future<void> _resetPassword() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_codeController.text.trim())) {
      _showMessage('กรุณากรอกรหัสยืนยัน 6 หลัก');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showMessage('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    setState(() => _isSaving = true);
    final error = await context.read<AuthProvider>().resetPassword(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
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
                'กรอกอีเมลของบัญชีเพื่อขอรหัสยืนยัน 6 หลัก (อายุ 15 นาที) '
                'ระบบยังไม่ส่งอีเมลจริง รหัสจะแสดงใน log ของ backend แทน',
                style: AppTypography.body(color: AppTheme.txtSecondary(context)),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'อีเมล',
                controller: _emailController,
                enabled: !_codeRequested,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                hint: 'example@email.com',
              ),
              if (!_codeRequested) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(label: 'ขอรหัสยืนยัน', onPressed: _requestCode, loading: _isRequesting),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'รหัสยืนยัน 6 หลัก',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                  hint: '123456',
                ),
                const SizedBox(height: AppSpacing.md),
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
