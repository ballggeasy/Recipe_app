import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.accentRed : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    await context.read<AuthProvider>().updateProfile(profileImagePath: picked.path);
    if (!mounted) return;
    _showMessage('อัปเดตรูปโปรไฟล์แล้ว');
  }

  Future<void> _editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แก้ไขชื่อ'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await context.read<AuthProvider>().updateProfile(name: newName);
      if (!mounted) return;
      _showMessage('อัปเดตชื่อแล้ว');
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เปลี่ยนรหัสผ่าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่านปัจจุบัน'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('บันทึก')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (newController.text.length < 6) {
      _showMessage('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร', isError: true);
      return;
    }

    final error = await context.read<AuthProvider>().changePassword(
          currentPassword: currentController.text,
          newPassword: newController.text,
        );

    if (!mounted) return;
    if (error != null) {
      _showMessage(error, isError: true);
    } else {
      _showMessage('เปลี่ยนรหัสผ่านสำเร็จ');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบบัญชี'),
        content: const Text('การลบบัญชีไม่สามารถย้อนกลับได้ และข้อมูลทั้งหมดจะถูกลบทิ้ง คุณแน่ใจหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('ลบบัญชี', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await context.read<AuthProvider>().deleteAccount();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.primLight(context),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'คุณใช้งานแบบผู้เยี่ยมชม',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.txtPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เข้าสู่ระบบเพื่อบันทึกสูตรโปรดและแผนมื้ออาหาร',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.txtSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.prim(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                      minimumSize: const Size(180, 50),
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header banner with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.prim(context),
            foregroundColor: Colors.white,
            title: const Text('โปรไฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.prim(context),
                      AppTheme.prim(context).withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Avatar with ring
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: AppTheme.primLight(context),
                              backgroundImage: user.profileImagePath != null
                                  ? FileImage(File(user.profileImagePath!))
                                  : null,
                              child: user.profileImagePath == null
                                  ? Icon(Icons.person, size: 44, color: AppTheme.prim(context))
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.prim(context),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: AppTheme.prim(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(text: 'ข้อมูลบัญชี'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.edit_outlined,
                        label: 'แก้ไขชื่อ',
                        onTap: () => _editName(user.name),
                      ),
                      _ProfileTile(
                        icon: Icons.lock_reset_rounded,
                        label: 'เปลี่ยนรหัสผ่าน',
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(text: 'การตั้งค่า'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: AppTheme.txtSecondary(context),
                        ),
                        title: Text(
                          'โหมดมืด',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.txtPrimary(context),
                          ),
                        ),
                        value: themeProvider.isDarkMode,
                        activeThumbColor: AppTheme.prim(context),
                        activeTrackColor: AppTheme.primLight(context),
                        onChanged: (value) => themeProvider.toggleTheme(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(text: 'จัดการบัญชี'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.logout_rounded,
                        label: 'ออกจากระบบ',
                        onTap: _logout,
                      ),
                      _ProfileTile(
                        icon: Icons.delete_outline_rounded,
                        label: 'ลบบัญชี',
                        labelColor: AppTheme.accRed(context),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.txtSecondary(context),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadow(context),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (labelColor ?? AppTheme.prim(context)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: labelColor ?? AppTheme.prim(context)),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: labelColor ?? AppTheme.txtPrimary(context),
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.txtSecondary(context), size: 20),
      onTap: onTap,
    );
  }
}
