import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ระบบตัวอักษร — Taviraj (เซอริฟหัวเรื่อง โทนบรรณาธิการ) คู่กับ
/// IBM Plex Sans Thai (ซานส์เนื้อหา/UI) รองรับภาษาไทยเต็มรูปแบบ
class AppTypography {
  AppTypography._();

  static TextStyle get _display => GoogleFonts.taviraj();
  static TextStyle get _body => GoogleFonts.ibmPlexSansThai();

  /// หัวเรื่องใหญ่สุด — หน้าแรก/หน้ารายละเอียดสูตร
  static TextStyle display({Color? color}) => _display.copyWith(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle h1({Color? color}) => _display.copyWith(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle h2({Color? color}) => _display.copyWith(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle h3({Color? color}) => _body.copyWith(
        fontSize: 15.5,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle body({Color? color}) => _body.copyWith(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyStrong({Color? color}) => _body.copyWith(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle caption({Color? color}) => _body.copyWith(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle button({Color? color}) => _body.copyWith(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle overline({Color? color}) => _body.copyWith(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      );
}
