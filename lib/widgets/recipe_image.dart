import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';

/// แสดงรูปภาพจริงของสูตรอาหารจาก imageUrl
/// ถ้า imageUrl ว่างเปล่าหรือโหลดไม่สำเร็จ จะ fallback กลับไปแสดง emoji แทนอัตโนมัติ
/// เพื่อไม่ให้แอป crash หรือโชว์ไอคอนรูปหักเมื่อ URL เสียหรือไม่มีอินเทอร์เน็ต
class RecipeImage extends StatelessWidget {
  final Recipe recipe;
  final double emojiSize;
  final BorderRadius? borderRadius;

  const RecipeImage({
    super.key,
    required this.recipe,
    this.emojiSize = 44,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final content = recipe.imageUrl.isEmpty
        ? _buildEmojiFallback(context)
        : Image.network(
            recipe.imageUrl,
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
            errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(context),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildEmojiFallback(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.primLight(context),
      child: Center(
        child: Text(recipe.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}
