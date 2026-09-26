import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/login_required.dart';
import '../../widgets/common/tap_target.dart';
import '../recipe/my_recipes_screen.dart';

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
        backgroundColor: isError ? AppTheme.error(context) : AppTheme.prim(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    try {
      await context.read<AuthProvider>().uploadAvatar(picked);
      if (!mounted) return;
      _showMessage('อัปเดตรูปโปรไฟล์แล้ว');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
    }
  }

  Future<void> _editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แก้ไขชื่อ'),
        content: AppTextField(controller: controller),
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
      try {
        await context.read<AuthProvider>().updateProfile(name: newName);
        if (!mounted) return;
        _showMessage('อัปเดตชื่อแล้ว');
      } on ApiException catch (e) {
        if (!mounted) return;
        _showMessage(e.message, isError: true);
      }
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
            AppTextField(
              controller: currentController,
              obscureText: true,
              label: 'รหัสผ่านปัจจุบัน',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: newController,
              obscureText: true,
              label: 'รหัสผ่านใหม่',
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
            child: Text('ลบบัญชี', style: TextStyle(color: AppTheme.error(dialogContext))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<AuthProvider>().deleteAccount();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
      return;
    }
    if (!mounted) return;
    goToLogin(Navigator.of(context));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    goToLogin(Navigator.of(context));
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.primLight(context),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Icon(Icons.person_rounded, size: 40, color: AppTheme.prim(context)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'คุณกำลังใช้งานแบบผู้เยี่ยมชม',
                  style: AppTypography.body(color: AppTheme.txtSecondary(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(
                  label: 'เข้าสู่ระบบ',
                  fullWidth: false,
                  onPressed: () => goToLogin(Navigator.of(context)),
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
          SliverAppBar(
            backgroundColor: AppTheme.prim(context),
            foregroundColor: AppTheme.onAccent(context),
            elevation: 0,
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                name: user.name,
                email: user.email,
                imagePath: user.profileImagePath,
                onEditPhoto: _pickImage,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สูตรอาหาร', style: AppTypography.overline(color: AppTheme.txtSecondary(context))),
                  const SizedBox(height: AppSpacing.sm),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.menu_book_outlined,
                        label: 'สูตรของฉัน',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('บัญชี', style: AppTypography.overline(color: AppTheme.txtSecondary(context))),
                  const SizedBox(height: AppSpacing.sm),
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
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('การแสดงผล', style: AppTypography.overline(color: AppTheme.txtSecondary(context))),
                  const SizedBox(height: AppSpacing.sm),
                  _SectionCard(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: AppTheme.txtSecondary(context),
                        ),
                        title: Text('โหมดมืด', style: AppTypography.body(color: AppTheme.txtPrimary(context))),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('อื่น ๆ', style: AppTypography.overline(color: AppTheme.txtSecondary(context))),
                  const SizedBox(height: AppSpacing.sm),
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
                        labelColor: AppTheme.error(context),
                        onTap: _deleteAccount,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? imagePath;
  final VoidCallback onEditPhoto;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.imagePath,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.prim(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.25)!],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TapTarget(
                onTap: onEditPhoto,
                label: 'เปลี่ยนรูปโปรไฟล์',
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: imagePath != null ? NetworkImage(imagePath!) : null,
                      child: imagePath == null
                          ? Icon(Icons.person_rounded, size: 44, color: AppTheme.onAccent(context))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.prim(context), width: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded, size: 15, color: AppTheme.prim(context)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: AppTypography.h1(color: AppTheme.onAccent(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTypography.caption(color: AppTheme.onAccent(context).withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.div(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final bool showDivider;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: labelColor ?? AppTheme.txtSecondary(context)),
          title: Text(
            label,
            style: AppTypography.body(color: labelColor ?? AppTheme.txtPrimary(context)),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.txtSecondary(context)),
          onTap: onTap,
        ),
        if (showDivider) Divider(height: 1, color: AppTheme.div(context)),
      ],
    );
  }
}
