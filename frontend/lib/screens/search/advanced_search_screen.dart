import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/search/search_bar_widget.dart';
import '../../widgets/common/filter_chip_widget.dart';
import '../../widgets/recipe_image.dart';
import '../../widgets/rating_display.dart';
import '../../widgets/source_badge.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/tap_target.dart';
import '../recipe/detail_screen.dart';

/// ค้นหาขั้นสูง — Filter, Sort, ค้นหาตามชื่อ/วัตถุดิบ/ประเภท/ประเทศ/เวลา/ความยาก
class AdvancedSearchScreen extends StatelessWidget {
  const AdvancedSearchScreen({super.key});

  SortOption _sortFromKey(String key) => switch (key) {
        'name_asc' => SortOption.nameAsc,
        'name_desc' => SortOption.nameDesc,
        'rating_desc' => SortOption.ratingDesc,
        'time_asc' => SortOption.timeAsc,
        'time_desc' => SortOption.timeDesc,
        'newest' => SortOption.newest,
        _ => SortOption.popular,
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาเมนู'),
        actions: [
          TextButton(
            onPressed: provider.clearFilters,
            child: const Text('ล้างทั้งหมด'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SearchBarWidget(showHistory: true),
          const SizedBox(height: AppSpacing.xl),
          _FilterGroup(
            label: 'ประเภทอาหาร',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: provider.categories.map((cat) {
                return FilterChipWidget(
                  label: cat,
                  isSelected: provider.selectedCategory == cat,
                  onTap: () => provider.updateSelectedCategory(cat),
                );
              }).toList(),
            ),
          ),
          _FilterGroup(
            label: 'ประเทศ',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: provider.countries.map((c) {
                return FilterChipWidget(
                  label: c,
                  isSelected: provider.selectedCountry == c,
                  onTap: () => provider.updateSelectedCountry(c),
                  filled: false,
                );
              }).toList(),
            ),
          ),
          _FilterGroup(
            label: 'ระดับความยาก',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChipWidget(
                  label: 'ทั้งหมด',
                  isSelected: provider.selectedDifficulty == null,
                  onTap: () => provider.updateSelectedDifficulty(null),
                ),
                ...AppConstants.difficulties.map(
                  (d) => FilterChipWidget(
                    label: d,
                    isSelected: provider.selectedDifficulty == d,
                    onTap: () => provider.updateSelectedDifficulty(d),
                  ),
                ),
              ],
            ),
          ),
          _FilterGroup(
            label: 'เวลาในการทำ (สูงสุด)',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [null, 15, 30, 45, 60].map((mins) {
                final label = mins == null ? 'ไม่จำกัด' : '$mins นาที';
                return FilterChipWidget(
                  label: label,
                  isSelected: provider.maxCookTime == mins,
                  onTap: () => provider.updateMaxCookTime(mins),
                  filled: false,
                );
              }).toList(),
            ),
          ),
          _FilterGroup(
            label: 'เรียงตาม',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: AppConstants.sortOptions.map((o) {
                final opt = _sortFromKey(o.$1);
                return FilterChipWidget(
                  label: o.$2,
                  isSelected: provider.sortOption == opt,
                  onTap: () => provider.updateSortOption(opt),
                  filled: false,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'ผลลัพธ์',
                style: AppTypography.h2(color: AppTheme.txtPrimary(context)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '(${recipes.length} เมนู)',
                style: AppTypography.body(color: AppTheme.txtSecondary(context)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (recipes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: EmptyState(
                emoji: '😕',
                message: 'ไม่พบเมนูที่ตรงเงื่อนไข',
                description: 'ลองปรับตัวกรองหรือคำค้นหาใหม่อีกครั้ง',
                actionLabel: 'ล้างตัวกรองทั้งหมด',
                onAction: provider.clearFilters,
              ),
            )
          else
            ...recipes.map(
              (recipe) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SearchResultCard(
                  recipe: recipe,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailScreen(recipe: recipe)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// การ์ดผลการค้นหาแบบแนวนอน — สแกนได้เร็วกว่ากริดเมื่อดูรายการยาว ๆ
class _SearchResultCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _SearchResultCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isFav = provider.isFavorite(recipe.id);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.div(context)),
            boxShadow: AppShadows.softFor(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: RecipeImage(recipe: recipe, emojiSize: 36),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SourceBadge(recipe: recipe, compact: true),
                      const SizedBox(height: 4),
                      Text(
                        recipe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3(color: AppTheme.txtPrimary(context)),
                      ),
                      const SizedBox(height: 2),
                      RatingDisplay(
                        rating: recipe.rating,
                        reviewCount: recipe.reviewCount,
                        fontSize: 11.5,
                        starSize: 13,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppTheme.txtSecondary(context)),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.totalTimeMinutes} นาที',
                            style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.bar_chart_rounded, size: 12, color: AppTheme.txtSecondary(context)),
                          const SizedBox(width: 3),
                          Text(recipe.difficulty, style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: TapTarget(
                  onTap: () => provider.toggleFavorite(recipe.id),
                  label: isFav ? 'เอาออกจากสูตรโปรด' : 'บันทึกเป็นสูตรโปรด',
                  selected: isFav,
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppTheme.error(context) : AppTheme.txtSecondary(context),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
