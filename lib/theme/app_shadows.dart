import 'package:flutter/material.dart';

/// เงาระดับเบา ใช้เฉพาะจุดที่ช่วยลำดับชั้นภาพ ไม่ใช้เงาหนัก
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14231D14), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0D231D14), blurRadius: 10, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1F231D14), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// เงาแทบมองไม่เห็นในโหมดมืด (พื้นหลังเข้มทำให้เงาสีดำไม่ช่วยลำดับชั้น) จึงคืนค่าว่าง
  static List<BoxShadow> cardFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const [] : card;

  static List<BoxShadow> softFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const [] : soft;
}
