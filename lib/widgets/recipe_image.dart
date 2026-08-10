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

  bool get _isAssetImage =>
      recipe.imageUrl.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final content = recipe.imageUrl.isEmpty
        ? _buildEmojiFallback()
        : _isAssetImage
            ? Image.asset(
                recipe.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    _buildEmojiFallback(),
              )
            : Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.primaryLight,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primary,
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
                    _buildEmojiFallback(),
              );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildEmojiFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.primaryLight,
      child: Center(
        child: Text(recipe.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}
