import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// ปุ่ม "ดำเนินการต่อด้วย Google" ที่ Google วาดเองบนเว็บ (ต้องใช้ปุ่มนี้ ไม่สามารถเรียกหน้าเลือกบัญชีเองได้)
/// Google กำหนดความสูงตายตัว (40px) และให้เลือกได้แค่ธีม รูปทรง และความกว้างตั้งแต่ 200 ถึง 400 px
/// จึงปรับให้กว้างเท่าปุ่มอื่นในฟอร์ม ทรงแคปซูลให้เข้ากับปุ่มที่โค้งมน และใช้ธีมมืดเมื่อแอปเป็นโหมดมืด
Widget renderGoogleButton({required double width, required bool dark}) =>
    web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: dark
            ? web.GSIButtonTheme.filledBlack
            : web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        minimumWidth: width,
        locale: 'th',
      ),
    );
