import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';

/// แสดงรูปภาพจริงของสูตรอาหาร ลำดับการเลือกรูป:
/// 1. รูปที่แถมมากับแอป (สูตรตัวอย่างที่ imageUrl ชี้ไปที่ Wikimedia ซึ่งลิงก์เสียหรือถูกจำกัดการเรียก)
/// 2. imageUrl ของสูตร (เช่นรูปที่ผู้ใช้อัปโหลด)
/// 3. ไอคอนอาหารสีกลาง ๆ ถ้าไม่มีรูปหรือโหลดไม่สำเร็จ (ไม่ใช้ emoji แทนรูปอีกต่อไป)
/// รูปเป็นแค่ส่วนตกแต่ง (ชื่อสูตรแสดงอยู่ข้าง ๆ เสมอ) จึงซ่อนจาก screen reader เพื่อไม่ให้อ่านชื่อซ้ำ
class RecipeImage extends StatelessWidget {
  final Recipe recipe;

  /// ขนาดของไอคอน fallback (ชื่อเดิมคือขนาด emoji จึงคงไว้เพื่อไม่ต้องแก้ทุกหน้าจอที่เรียกใช้)
  final double emojiSize;
  final BorderRadius? borderRadius;

  const RecipeImage({
    super.key,
    required this.recipe,
    this.emojiSize = 44,
    this.borderRadius,
  });

  /// ส่วนหนึ่งของชื่อไฟล์ใน imageUrl เดิมของสูตรตัวอย่าง -> รูปที่แถมมากับแอป
  /// จับคู่จาก URL ไม่ใช่ชื่อสูตร เพื่อให้ยังได้รูปถูกแม้ผู้ใช้แก้ชื่อสูตร
  static const _bundledPhotos = <String, String>{
    'Kapow_and_egg': 'pad_krapao.jpg',
    'Tom_yum_kung': 'tom_yum_kung.jpg',
    'Korean.fried.chicken': 'korean_fried_chicken.jpg',
    'Kimchi_jjigae': 'kimchi_jjigae.jpg',
    'Tteokbokki': 'tteokbokki.jpg',
    'Bibimbap': 'bibimbap.png',
    'Pot-stickers': 'steamed_dumplings.jpg',
    'Sweet_and_sour_pork': 'sweet_and_sour_pork.jpg',
    'Salted_egg_fried_rice': 'salted_egg_fried_rice.png',
    'Takoyaki': 'takoyaki.png',
    'Salmon_and_shrimp_don': 'salmon_don.png',
    'Shoyu_ramen': 'shoyu_ramen.jpg',
    'Tiramisu': 'tiramisu.png',
    'pizza-margherita': 'pizza_margherita.jpg',
    'Carbonara': 'carbonara.jpg',
    'Som_tam_thai': 'som_tum.jpg',
  };

  /// path ของรูปที่แถมมากับแอปสำหรับสูตรนี้ หรือ null ถ้าไม่ใช่สูตรตัวอย่าง
  static String? bundledPhotoFor(String imageUrl) {
    for (final entry in _bundledPhotos.entries) {
      if (imageUrl.contains(entry.key)) {
        return 'assets/images/recipes/${entry.value}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bundled = bundledPhotoFor(recipe.imageUrl);
    final Widget content;
    if (bundled != null) {
      content = Image.asset(
        bundled,
        excludeFromSemantics: true,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(context),
      );
    } else if (recipe.imageUrl.isEmpty) {
      content = _buildPlaceholder(context);
    } else {
      content = Image.network(
        recipe.imageUrl,
        excludeFromSemantics: true,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppTheme.primLight(context),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.prim(context),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.primLight(context),
      child: Center(
        child: ExcludeSemantics(
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: emojiSize,
            color: AppTheme.prim(context),
          ),
        ),
      ),
    );
  }
}
