import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// ปุ่ม "ดำเนินการต่อด้วย Google" ที่ Google วาดเองบนเว็บ (ต้องใช้ปุ่มนี้ ไม่สามารถเรียกหน้าเลือกบัญชีเองได้)
Widget renderGoogleButton() => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    type: web.GSIButtonType.standard,
    theme: web.GSIButtonTheme.outline,
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.continueWith,
    shape: web.GSIButtonShape.rectangular,
    minimumWidth: 240,
    locale: 'th',
  ),
);
