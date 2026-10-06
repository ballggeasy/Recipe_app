import 'package:flutter/widgets.dart';

/// แพลตฟอร์มที่ไม่ใช่เว็บไม่มีปุ่มของ Google (ใช้ [PlatformGoogleSignInService.signIn] แทน)
Widget renderGoogleButton({required double width, required bool dark}) =>
    const SizedBox.shrink();
