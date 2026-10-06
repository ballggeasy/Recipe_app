import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// เช็คก่อนทำสิ่งที่ต้องมีบัญชี (รีวิว, คอมเมนต์, แผนมื้ออาหาร, โฟลเดอร์)
/// คืน true ถ้าล็อกอินอยู่ — ถ้าเป็นผู้เยี่ยมชมจะแสดง [message] พร้อมปุ่มไปหน้าล็อกอินแล้วคืน false
/// (เดิมผู้เยี่ยมชมกดได้แต่ request โดน 401 แล้วล้มเงียบ ๆ)
bool requireLogin(BuildContext context, String message) {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) return true;

  // ScaffoldMessenger อยู่ระดับแอป ปุ่มใน SnackBar อาจถูกกดหลังหน้านี้ปิดไปแล้ว จึงเก็บ navigator ไว้ก่อน
  final navigator = Navigator.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'เข้าสู่ระบบ',
          onPressed: () {
            navigator.popUntil((route) => route.isFirst);
            auth.goToLogin();
          },
        ),
      ),
    );
  return false;
}
