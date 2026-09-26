// ตรวจ contrast ของคู่สีข้อความ/พื้นหลังที่ใช้จริงในแอปตามเกณฑ์ WCAG AA (ข้อความปกติ >= 4.5:1)
// ทั้งโหมดสว่างและมืด — ถ้าปรับสีใน AppColors แล้ว test นี้ fail แปลว่าข้อความบางจุดจะอ่านยาก
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/theme/app_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void _expectReadable(String name, Color text, Color background) {
  final ratio = _contrast(text, background);
  expect(ratio, greaterThanOrEqualTo(4.5), reason: '$name: ${ratio.toStringAsFixed(2)}:1 is below WCAG AA 4.5:1');
}

void main() {
  group('light mode', () {
    const backgrounds = {
      'background': AppColors.background,
      'surface': AppColors.surface,
      'surfaceMuted': AppColors.surfaceMuted,
    };

    for (final bg in backgrounds.entries) {
      test('text colors are readable on ${bg.key}', () {
        _expectReadable('textPrimary', AppColors.textPrimary, bg.value);
        _expectReadable('textSecondary', AppColors.textSecondary, bg.value);
        _expectReadable('primary (links)', AppColors.primary, bg.value);
        _expectReadable('error', AppColors.error, bg.value);
        _expectReadable('secondary', AppColors.secondary, bg.value);
      });
    }

    test('text on accent fills is readable', () {
      _expectReadable('onAccent on primary', AppColors.onAccent, AppColors.primary);
      _expectReadable('onAccent on secondary', AppColors.onAccent, AppColors.secondary);
      _expectReadable('onAccent on error', AppColors.onAccent, AppColors.error);
    });

    test('text on muted tints is readable', () {
      _expectReadable('primary on primaryMuted', AppColors.primary, AppColors.primaryMuted);
      _expectReadable('secondary on secondaryMuted', AppColors.secondary, AppColors.secondaryMuted);
      _expectReadable('error on errorMuted', AppColors.error, AppColors.errorMuted);
    });
  });

  group('dark mode', () {
    const backgrounds = {
      'background': AppColors.backgroundDark,
      'surface': AppColors.surfaceDark,
      'surfaceMuted': AppColors.surfaceMutedDark,
    };

    for (final bg in backgrounds.entries) {
      test('text colors are readable on ${bg.key}', () {
        _expectReadable('textPrimary', AppColors.textPrimaryDark, bg.value);
        _expectReadable('textSecondary', AppColors.textSecondaryDark, bg.value);
        _expectReadable('primary (links)', AppColors.primaryDark, bg.value);
        _expectReadable('error', AppColors.errorDark, bg.value);
        _expectReadable('secondary', AppColors.secondaryDark, bg.value);
      });
    }

    test('text on accent fills is readable', () {
      _expectReadable('onAccent on primary', AppColors.onAccentDark, AppColors.primaryDark);
      _expectReadable('onAccent on secondary', AppColors.onAccentDark, AppColors.secondaryDark);
      _expectReadable('onAccent on error', AppColors.onAccentDark, AppColors.errorDark);
    });

    test('text on muted tints is readable', () {
      _expectReadable('primary on primaryMuted', AppColors.primaryDark, AppColors.primaryMutedDark);
      _expectReadable('secondary on secondaryMuted', AppColors.secondaryDark, AppColors.secondaryMutedDark);
      _expectReadable('error on errorMuted', AppColors.errorDark, AppColors.errorMutedDark);
    });
  });
}
