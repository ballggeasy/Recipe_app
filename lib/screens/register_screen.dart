import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
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
  bool _obscure = true;

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
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        backgroundColor: AppTheme.bg(context),
        foregroundColor: AppTheme.txtPrimary(context),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primLight(context).withOpacity(0.5),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: (size.width > 600) ? size.width * 0.2 : 20,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surf(context),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.shadow(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สร้างบัญชีใหม่',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.txtPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'กรอกข้อมูลเพื่อเริ่มต้นใช้งาน',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.txtSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _Field(
                          label: 'ชื่อ',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          hint: 'ชื่อของคุณ',
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label: 'อีเมล',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label: 'รหัสผ่าน',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          hint: '••••••••',
                          obscureText: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppTheme.txtSecondary(context),
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label: 'ยืนยันรหัสผ่าน',
                          controller: _confirmController,
                          icon: Icons.lock_outline_rounded,
                          hint: '••••••••',
                          obscureText: _obscure,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.prim(context),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppTheme.prim(context).withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusButton)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    'สมัครสมาชิก',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint = '',
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            border: Border.all(color: AppTheme.div(context)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
                fontSize: 14.5, color: AppTheme.txtPrimary(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: AppTheme.txtSecondary(context), fontSize: 14),
              prefixIcon:
                  Icon(icon, size: 20, color: AppTheme.txtSecondary(context)),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}