import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../providers/recipe_provider.dart';
import 'recipe_image.dart';
import 'rating_display.dart';
import 'source_badge.dart';

/// การ์ดแสดงข้อมูลสูตรอาหารแบบย่อ ใช้ในหน้า browse และ favorites
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isFav = provider.isFavorite(recipe.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.shadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusCard),
                      ),
                      child: RecipeImage(recipe: recipe, emojiSize: 44),
                    ),
                  ),
                  // gradient overlay สำหรับ source badge area
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusCard),
                      ),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 40,
                    child: SourceBadge(recipe: recipe, compact: true),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _FavoriteButton(
                      isFav: isFav,
                      onTap: () => provider.toggleFavorite(recipe.id),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.txtPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 5),
                  RatingDisplay(
                    rating: recipe.rating,
                    reviewCount: recipe.reviewCount,
                    fontSize: 11.5,
                    starSize: 13,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.txtSecondary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.cookTimeMinutes} นาที',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.txtSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool isFav;
  final VoidCallback onTap;
  const _FavoriteButton({required this.isFav, required this.onTap});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _controller.reverse();
    widget.onTap();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 17,
            color: widget.isFav ? AppTheme.accentRed : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
