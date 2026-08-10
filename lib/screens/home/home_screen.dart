import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/recipe_data.dart';
import '../../theme/app_theme.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/common/filter_chip_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/search/search_bar_widget.dart';
import '../recipe/detail_screen.dart';
import '../recipe/add_recipe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  SortOption _sortFromKey(String key) => switch (key) {
        'name_asc' => SortOption.nameAsc,
        'name_desc' => SortOption.nameDesc,
        'rating_desc' => SortOption.ratingDesc,
        'time_asc' => SortOption.timeAsc,
        'time_desc' => SortOption.timeDesc,
        'newest' => SortOption.newest,
        _ => SortOption.popular,
      };

  void _showSortSheet(BuildContext context, RecipeProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortBottomSheet(
        currentSort: provider.sortOption,
        onSelected: provider.updateSortOption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.filteredRecipes;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
        ),
        backgroundColor: AppTheme.prim(context),
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'เพิ่มสูตร',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ที่ collapse ได้เมื่อ scroll ──
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: AppTheme.bg(context),
            foregroundColor: AppTheme.txtPrimary(context),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'สูตรอาหาร',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.txtPrimary(context),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.sort_rounded, color: AppTheme.txtPrimary(context)),
                tooltip: 'เรียงลำดับ',
                onPressed: () => _showSortSheet(context, provider),
              ),
              const SizedBox(width: 4),
            ],
            // Search bar อยู่ใน bottom ของ SliverAppBar
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SearchBarWidget(showHistory: true),
              ),
            ),
          ),

          // ── Filter rows ทั้งหมด (scroll หายขึ้นไปได้) ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterSection(
                  label: 'มุมมอง',
                  height: 40,
                  child: _HomeSections(provider: provider),
                ),
                _FilterSection(
                  label: 'อาหาร',
                  height: 36,
                  child: _DietTagsRow(provider: provider),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: _FilterLabel(text: 'แหล่งสูตร'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: _SourceFilterRow(provider: provider),
                ),
                _FilterSection(
                  label: 'หมวดหมู่',
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: RecipeData.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = RecipeData.categories[index];
                      return FilterChipWidget(
                        label: category,
                        isSelected: provider.selectedCategory == category,
                        onTap: () => provider.updateSelectedCategory(category),
                      );
                    },
                  ),
                ),
                _FilterSection(
                  label: 'ประเทศ',
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: RecipeData.countries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final country = RecipeData.countries[index];
                      return FilterChipWidget(
                        label: country == 'ทั้งหมด'
                            ? '🌏 ทั้งหมด'
                            : '${_countryFlag(country)} $country',
                        isSelected: provider.selectedCountry == country,
                        onTap: () => provider.updateSelectedCountry(country),
                        filled: false,
                      );
                    },
                  ),
                ),
                Divider(height: 1, color: AppTheme.div(context)),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Recipe grid หรือ empty state ──
          if (recipes.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                message: 'ไม่พบเมนูที่ตรงกัน',
                subtitle: 'ลองเปลี่ยนตัวกรองหรือค้นหาด้วยคำอื่น',
                actionLabel: 'ล้างตัวกรอง',
                onAction: provider.clearFilters,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = recipes[index];
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(recipe: recipe),
                        ),
                      ),
                    );
                  },
                  childCount: recipes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sort Bottom Sheet ──

class _SortBottomSheet extends StatelessWidget {
  final SortOption currentSort;
  final ValueChanged<SortOption> onSelected;

  const _SortBottomSheet({
    required this.currentSort,
    required this.onSelected,
  });

  static const _options = [
    (SortOption.nameAsc,    Icons.sort_by_alpha_rounded,     'ชื่อ A-Z'),
    (SortOption.nameDesc,   Icons.sort_by_alpha_rounded,     'ชื่อ Z-A'),
    (SortOption.ratingDesc, Icons.star_rounded,              'คะแนนสูงสุด'),
    (SortOption.timeAsc,    Icons.timer_outlined,            'เวลาน้อยสุด'),
    (SortOption.timeDesc,   Icons.timer_off_outlined,        'เวลามากสุด'),
    (SortOption.newest,     Icons.fiber_new_rounded,         'ล่าสุด'),
    (SortOption.popular,    Icons.local_fire_department_rounded, 'ยอดนิยม'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppTheme.shadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.div(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primLight(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sort_rounded, size: 18, color: AppTheme.prim(context)),
                ),
                const SizedBox(width: 12),
                Text(
                  'เรียงลำดับ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.txtPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.div(context)),
          // Options list
          ...List.generate(_options.length, (i) {
            final (sort, icon, label) = _options[i];
            final isSelected = currentSort == sort;
            return InkWell(
              onTap: () {
                onSelected(sort);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primLight(context)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.prim(context)
                            : AppTheme.bg(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.txtSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.prim(context)
                              : AppTheme.txtPrimary(context),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          size: 20, color: AppTheme.prim(context)),
                  ],
                ),
              ),
            );
          }),
          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

String _countryFlag(String country) => switch (country) {
      'ไทย' => '🇹🇭',
      'อิตาลี' => '🇮🇹',
      'ญี่ปุ่น' => '🇯🇵',
      'จีน' => '🇨🇳',
      'เกาหลี' => '🇰🇷',
      _ => '🌏',
    };

// ── Helper Widgets ──

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  final double height;

  const _FilterSection({
    required this.label,
    required this.child,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: _FilterLabel(text: label),
        ),
        SizedBox(height: height, child: child),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.txtSecondary(context),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _HomeSections extends StatelessWidget {
  final RecipeProvider provider;
  const _HomeSections({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: AppConstants.homeSections.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
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
          onTap: () => provider.updateListMode(
            isSelected ? RecipeListMode.all : mode,
          ),
        );
      },
    );
  }
}

class _DietTagsRow extends StatelessWidget {
  final RecipeProvider provider;
  const _DietTagsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: AppConstants.dietTags.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final tag = AppConstants.dietTags[index];
        final isSelected = provider.selectedDietTag == tag;
        return FilterChipWidget(
          label: tag,
          isSelected: isSelected,
          onTap: () => provider.updateListMode(
            isSelected ? RecipeListMode.all : RecipeListMode.diet,
            dietTag: isSelected ? null : tag,
          ),
          filled: false,
        );
      },
    );
  }
}

class _SourceFilterRow extends StatelessWidget {
  final RecipeProvider provider;
  const _SourceFilterRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final options = [
      (SourceFilter.all, 'ทั้งหมด', null),
      (SourceFilter.official, 'ทางการ', Icons.verified_rounded),
      (SourceFilter.user, 'ผู้ใช้', Icons.person_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.div(context)),
      ),
      child: Row(
        children: options.map((option) {
          final (value, label, icon) = option;
          final isSelected = provider.selectedSource == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.updateSelectedSource(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.prim(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.txtSecondary(context),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.txtSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
