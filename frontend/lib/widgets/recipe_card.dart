import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppTheme.div(context)),
            boxShadow: AppShadows.softFor(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RecipeImage(recipe: recipe, emojiSize: 40),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 40,
                      child: SourceBadge(recipe: recipe, compact: true),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
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
                      style: AppTypography.h3(color: AppTheme.txtPrimary(context)),
                    ),
                    const SizedBox(height: 6),
                    RatingDisplay(
                      rating: recipe.rating,
                      reviewCount: recipe.reviewCount,
                      fontSize: 11.5,
                      starSize: 13,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: AppTheme.txtSecondary(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookTimeMinutes} นาที',
                          style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.bar_chart_rounded, size: 13, color: AppTheme.txtSecondary(context)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            recipe.difficulty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
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
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFav;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFav, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFav),
            size: 18,
            color: isFav ? AppTheme.error(context) : AppTheme.txtSecondary(context),
          ),
        ),
      ),
    );
  }
}
