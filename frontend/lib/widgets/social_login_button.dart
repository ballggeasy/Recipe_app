import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// ปุ่ม "ดำเนินการต่อด้วย Google" ของหน้า login และ register (มือถือ)
/// สูง 52 มุมโค้งเท่าปุ่มอื่นในแอป โลโก้ Google สี่สีของจริงกับข้อความอยู่กึ่งกลางเป็นกลุ่มเดียว
/// สถานะ: ปกติ, กดค้าง, กำลังเข้าสู่ระบบ ([loading]) และใช้ไม่ได้ ([onTap] เป็น null)
/// บนเว็บ Google บังคับให้ใช้ปุ่มของ Google เอง ปุ่มนี้จึงใช้เฉพาะมือถือ
class GoogleSignInFace extends StatefulWidget {
  static const label = 'ดำเนินการต่อด้วย Google';
  static const height = 52.0;

  final VoidCallback? onTap;
  final bool loading;

  const GoogleSignInFace({
    super.key,
    required this.onTap,
    this.loading = false,
  });

  @override
  State<GoogleSignInFace> createState() => _GoogleSignInFaceState();
}

class _GoogleSignInFaceState extends State<GoogleSignInFace> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final enabled = widget.onTap != null && !widget.loading;
    final radius = BorderRadius.circular(AppRadius.lg);
    final pressed = _pressed && enabled;

    final background = pressed
        ? (dark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted)
        : (dark ? AppColors.surfaceDark : AppColors.surface);
    final border = pressed
        ? (dark ? const Color(0xFF7A6A58) : const Color(0xFFC2B3A0))
        : (dark ? const Color(0xFF5A4D3F) : const Color(0xFFD5C8B8));

    return Semantics(
      button: true,
      enabled: enabled,
      focusable: enabled,
      label: GoogleSignInFace.label,
      // ข้อความและโลโก้ข้างในถูกซ่อน (ไม่อ่านซ้ำ) จึงต้องบอก action ที่นี่เอง ไม่เช่นนั้น TalkBack จะอ่านว่าเป็นปุ่มที่กดไม่ได้
      onTap: enabled ? widget.onTap : null,
      excludeSemantics: true,
      child: Opacity(
        // ใช้ไม่ได้ = จางลงครึ่งหนึ่ง ส่วนตอนกำลังโหลดยังเห็นชัดเพราะกำลังทำงานอยู่
        opacity: widget.onTap == null ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: GoogleSignInFace.height,
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: Border.all(color: border),
            // เงาบางๆ ให้ปุ่มขาวไม่จมบนพื้นครีม (โหมดมืดและตอนกดไม่ใช้)
            boxShadow: dark || pressed
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0F231D14),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? widget.onTap : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: radius,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: widget.loading
                          ? CircularProgressIndicator(
                              strokeWidth: 3,
                              color: dark
                                  ? const Color(0xFF7BA7F5)
                                  : const Color(0xFF4285F4),
                              backgroundColor: dark
                                  ? AppColors.dividerDark
                                  : const Color(0xFFE6DACB),
                            )
                          : const CustomPaint(painter: _GoogleLogoPainter()),
                    ),
                    const SizedBox(width: 12),
                    // Flexible: จอแคบหรือตัวอักษรใหญ่ข้อความย่อด้วย … แทนที่จะล้นขอบปุ่ม
                    Flexible(
                      child: Text(
                        widget.loading
                            ? 'กำลังเข้าสู่ระบบ…'
                            : GoogleSignInFace.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong(
                          color: AppTheme.txtPrimary(context),
                        ).copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// โลโก้ Google สี่สี วาดเองจาก path ทางการ (ช่อง 48x48) จึงคมทุกขนาดและไม่ต้องเพิ่ม package/ไฟล์ภาพ
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()..style = PaintingStyle.fill;
    // red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(24, 9.5)
        ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
        ..lineTo(40.06, 6.25)
        ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
        ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
        ..lineTo(10.54, 19.41)
        ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
        ..close(),
      paint,
    );
    // blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(46.98, 24.55)
        ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
        ..lineTo(24, 20)
        ..lineTo(24, 29.02)
        ..lineTo(36.94, 29.02)
        ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
        ..lineTo(39.89, 42.2)
        ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
        ..close(),
      paint,
    );
    // yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(10.53, 28.59)
        ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
        ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
        ..lineTo(2.55, 13.22)
        ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
        ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
        ..lineTo(10.53, 28.59)
        ..close(),
      paint,
    );
    // green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(24, 48)
        ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
        ..lineTo(32.16, 36.19)
        ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
        ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
        ..lineTo(2.55, 34.77)
        ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
