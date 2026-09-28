import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/recipe_image.dart';
import '../../widgets/rating_display.dart';
import '../../widgets/common/filter_chip_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/login_required.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/tap_target.dart';
import '../../widgets/search/search_bar_widget.dart';
import '../profile/profile_screen.dart';
import '../recipe/detail_screen.dart';
import '../recipe/recipe_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Recipe? _featuredRecipe(RecipeProvider provider) {
    if (provider.allRecipes.isEmpty) return null;
    final recommended = provider.allRecipes.where((r) => r.isRecommended).toList();
    final pool = recommended.isNotEmpty ? recommended : provider.allRecipes;
    final sorted = [...pool]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'สวัสดีตอนเช้า';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final auth = context.watch<AuthProvider>();
    final recipes = provider.filteredRecipes;
    final featured = provider.searchQuery.isEmpty ? _featuredRecipe(provider) : null;
    final resultsTitle = provider.searchQuery.isNotEmpty || provider.selectedCategory != 'ทั้งหมด'
        ? 'ผลการค้นหา'
        : 'เมนูแนะนำสำหรับคุณ';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_add_recipe_fab',
        // เพิ่มสูตรได้เฉพาะบัญชีที่ล็อกอิน (backend ก็ตอบ 401) — ผู้เยี่ยมชมได้ข้อความพร้อมปุ่มไปเข้าสู่ระบบ
        onPressed: () {
          if (!ensureLoggedIn(context, action: 'เพิ่มสูตรอาหาร')) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen()));
        },
        backgroundColor: AppTheme.prim(context),
        icon: Icon(Icons.add_rounded, color: AppTheme.onAccent(context)),
        label: Text('เพิ่มสูตร', style: TextStyle(color: AppTheme.onAccent(context))),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()} 👋',
                            style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.currentUser != null
                                ? 'วันนี้ ${auth.currentUser!.name} จะทำอะไรดี?'
                                : 'วันนี้กินอะไรดี?',
                            style: AppTypography.display(color: AppTheme.txtPrimary(context))
                                .copyWith(fontSize: 22),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    TapTarget(
                      label: 'โปรไฟล์',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primLight(context),
                          border: Border.all(color: AppTheme.surf(context), width: 2),
                          boxShadow: AppShadows.softFor(context),
                        ),
                        child: Icon(Icons.person_rounded, color: AppTheme.prim(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    const Expanded(child: SearchBarWidget()),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterButton(onTap: () => _openFilterSheet(context)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SizedBox(
                  height: kMinInteractiveDimension,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: provider.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return FilterChipWidget(
                        label: category,
                        isSelected: provider.selectedCategory == category,
                        onTap: () => provider.updateSelectedCategory(category),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _QuickPicksRow(provider: provider),
              ),
            ),
            if (featured != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                  child: _FeaturedRecipeCard(
                    recipe: featured,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailScreen(recipe: featured)),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                child: SectionHeader(
                  title: resultsTitle,
                  actionLabel: recipes.isNotEmpty ? '${recipes.length} เมนู' : null,
                ),
              ),
            ),
            if (recipes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  emoji: '🍽️',
                  message: 'ไม่พบเมนูที่ตรงกับการค้นหา',
                  description: 'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรองดูนะ',
                  actionLabel: 'ล้างตัวกรอง',
                  onAction: provider.clearFilters,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailScreen(recipe: recipe)),
                        ),
                      );
                    },
                    childCount: recipes.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isActive = provider.selectedSource != SourceFilter.all ||
        provider.selectedDietTag != null ||
        provider.selectedCountry != 'ทั้งหมด' ||
        provider.sortOption != SortOption.ratingDesc;

    return Tooltip(
      message: 'ตัวกรองเพิ่มเติม',
      child: Material(
        color: isActive ? AppTheme.prim(context) : AppTheme.surf(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: isActive ? Colors.transparent : AppTheme.div(context)),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isActive ? AppTheme.onAccent(context) : AppTheme.txtSecondary(context),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPicksRow extends StatelessWidget {
  final RecipeProvider provider;
  const _QuickPicksRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinInteractiveDimension,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: AppConstants.homeSections.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (key, label, emoji) = AppConstants.homeSections[index];
          final mode = switch (key) {
            'latest' => RecipeListMode.latest,
            'popular' => RecipeListMode.popular,
            'recommended' => RecipeListMode.recommended,
            'random' => RecipeListMode.random,
            _ => RecipeListMode.seasonal,
          };
          final isSelected = provider.listMode == mode;
          return FilterChipWidget(
            label: '$emoji $label',
            isSelected: isSelected,
            filled: false,
            onTap: () => provider.updateListMode(
              isSelected ? RecipeListMode.all : mode,
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _FeaturedRecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isFav = provider.isFavorite(recipe.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.cardFor(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RecipeImage(recipe: recipe, emojiSize: 72),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                  stops: const [0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'เมนูแนะนำวันนี้',
                  style: AppTypography.overline(color: AppTheme.prim(context)),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: TapTarget(
                onTap: () => provider.toggleFavorite(recipe.id),
                label: isFav ? 'เอาออกจากสูตรโปรด' : 'บันทึกเป็นสูตรโปรด',
                selected: isFav,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h1(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Pill(
                        icon: Icons.access_time_rounded,
                        label: '${recipe.totalTimeMinutes} นาที',
                      ),
                      const SizedBox(width: 8),
                      _Pill(icon: Icons.bar_chart_rounded, label: recipe.difficulty),
                      const SizedBox(width: 8),
                      RatingDisplay(
                        rating: recipe.rating,
                        reviewCount: recipe.reviewCount,
                        fontSize: 12,
                        starSize: 14,
                        showCount: false,
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

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

/// แผ่นตัวกรองเพิ่มเติม — แหล่งที่มา, แท็กโภชนาการ, ประเทศ, การเรียงลำดับ
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  static const _sourceOptions = [
    (SourceFilter.all, 'ทั้งหมด', null),
    (SourceFilter.official, 'ทางการ', Icons.verified_rounded),
    (SourceFilter.user, 'ผู้ใช้', Icons.person_rounded),
  ];

  String _countryFlag(String country) => switch (country) {
        'ไทย' => '🇹🇭',
        'อิตาลี' => '🇮🇹',
        'ญี่ปุ่น' => '🇯🇵',
        'จีน' => '🇨🇳',
        'เกาหลี' => '🇰🇷',
        _ => '🌏',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.div(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Expanded(child: Text('ตัวกรอง', style: AppTypography.h2(color: AppTheme.txtPrimary(context)))),
                    TextButton(
                      onPressed: provider.clearFilters,
                      child: const Text('ล้างทั้งหมด'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xxl),
                  children: [
                    Text('แหล่งที่มา', style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _sourceOptions.map((o) {
                        final (value, label, icon) = o;
                        return FilterChipWidget(
                          label: label,
                          icon: icon,
                          isSelected: provider.selectedSource == value,
                          onTap: () => provider.updateSelectedSource(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('แท็กโภชนาการ', style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: AppConstants.dietTags.map((tag) {
                        final isSelected = provider.selectedDietTag == tag;
                        return FilterChipWidget(
                          label: tag,
                          isSelected: isSelected,
                          filled: false,
                          onTap: () => provider.updateListMode(
                            isSelected ? RecipeListMode.all : RecipeListMode.diet,
                            dietTag: isSelected ? null : tag,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('ประเทศ', style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: provider.countries.map((c) {
                        return FilterChipWidget(
                          label: c == 'ทั้งหมด' ? '🌏 ทั้งหมด' : '${_countryFlag(c)} $c',
                          isSelected: provider.selectedCountry == c,
                          filled: false,
                          onTap: () => provider.updateSelectedCountry(c),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('เรียงตาม', style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: AppConstants.sortOptions.map((o) {
                        final opt = o.$1;
                        return FilterChipWidget(
                          label: o.$2,
                          isSelected: provider.sortOption == opt,
                          filled: false,
                          onTap: () => provider.updateSortOption(opt),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ดูผลลัพธ์'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
