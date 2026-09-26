import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';

/// ไปหน้าเข้าสู่ระบบโดยล้าง stack เดิม (ผู้เยี่ยมชมไม่มีหน้าไหนต้องย้อนกลับไป)
void goToLogin(NavigatorState navigator) {
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// เช็คก่อนทำสิ่งที่ backend ต้องมีบัญชี (เพิ่มสูตร, เขียนรีวิว, วางแผนมื้อ ฯลฯ)
/// ถ้าเป็นผู้เยี่ยมชมจะแจ้งด้วย SnackBar พร้อมปุ่มไปเข้าสู่ระบบ แล้วคืน false
/// แทนที่จะปล่อยให้ request โดน 401 แบบเงียบ ๆ
bool ensureLoggedIn(BuildContext context, {required String action}) {
  if (context.read<AuthProvider>().isLoggedIn) return true;
  // เก็บ navigator ไว้ก่อน — ผู้ใช้อาจกดปุ่มใน SnackBar หลังจาก context นี้หายไปแล้ว
  final navigator = Navigator.of(context);
  ScaffoldMessenger.of(context)
    // กดซ้ำหลายปุ่มติดกันให้เห็นแค่ข้อความล่าสุด ไม่ต่อคิวยาว
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('กรุณาเข้าสู่ระบบเพื่อ$action'),
        action: SnackBarAction(label: 'เข้าสู่ระบบ', onPressed: () => goToLogin(navigator)),
        // SnackBar ที่มีปุ่มจะค้างจนกว่าจะปิดเอง (persist เป็น true โดยอัตโนมัติ) ซึ่งจะบังปุ่มด้านล่างของหน้า
        // ให้หายเองตามเวลาปกติ แต่ค้างไว้เมื่อเปิด screen reader เพื่อให้มีเวลาไปถึงปุ่ม "เข้าสู่ระบบ"
        persist: MediaQuery.accessibleNavigationOf(context),
      ),
    );
  return false;
}

/// แสดง error ที่ provider คืนมา (null = สำเร็จ ไม่ต้องแสดงอะไร)
void showErrorIfAny(BuildContext context, String? error) {
  if (error == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
}
