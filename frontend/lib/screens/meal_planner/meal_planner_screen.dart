import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/meal_planner_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../models/recipe.dart';
import '../../models/meal_plan.dart';
import '../../models/nutrition.dart';
import '../../widgets/common/empty_state.dart';
import '../recipe/detail_screen.dart';

/// Meal Planner — วางแผนรายวัน/สัปดาห์/เดือน + คำนวณแคลอรี/สารอาหาร
class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<MealPlannerProvider>();
    final recipes = context.watch<RecipeProvider>().allRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('วางแผนมื้ออาหาร'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'รายวัน'),
            Tab(text: 'รายสัปดาห์'),
            Tab(text: 'รายเดือน'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'meal_planner_add_fab',
        onPressed: () => _showAddMealDialog(context),
        backgroundColor: AppTheme.prim(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DailyView(
            date: _selectedDate,
            entries: planner.entriesForDate(_selectedDate),
            nutrition: planner.nutritionForDate(_selectedDate, recipes),
            onDateChanged: (d) => setState(() => _selectedDate = d),
            recipes: recipes,
          ),
          _WeeklyView(
            weekStart: _weekStart(_selectedDate),
            entries: planner.entriesForWeek(_weekStart(_selectedDate)),
            nutrition: planner.nutritionForWeek(_weekStart(_selectedDate), recipes),
            recipes: recipes,
          ),
          _MonthlyView(
            month: _selectedDate.month,
            year: _selectedDate.year,
            entries: planner.entriesForMonth(_selectedDate.year, _selectedDate.month),
            recipes: recipes,
          ),
        ],
      ),
    );
  }

  DateTime _weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _showAddMealDialog(BuildContext context) {
    final recipes = context.read<RecipeProvider>().allRecipes;
    final planner = context.read<MealPlannerProvider>();
    String? selectedRecipeId = recipes.isNotEmpty ? recipes.first.id : null;
    MealType selectedMeal = MealType.lunch;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('เพิ่มมื้ออาหาร'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRecipeId,
                decoration: const InputDecoration(labelText: 'เลือกเมนู'),
                items: recipes
                    .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRecipeId = v),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MealType>(
                initialValue: selectedMeal,
                decoration: const InputDecoration(labelText: 'มื้อ'),
                items: MealType.values
                    .map((m) => DropdownMenuItem(value: m, child: Text('${m.emoji} ${m.label}')))
                    .toList(),
                onChanged: (v) => setState(() => selectedMeal = v ?? MealType.lunch),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            TextButton(
              onPressed: () {
                if (selectedRecipeId != null) {
                  planner.addEntry(
                    recipeId: selectedRecipeId!,
                    date: _selectedDate,
                    mealType: selectedMeal,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyView extends StatelessWidget {
  final DateTime date;
  final List<MealPlanEntry> entries;
  final NutritionInfo nutrition;
  final ValueChanged<DateTime> onDateChanged;
  final List<Recipe> recipes;

  const _DailyView({
    required this.date,
    required this.entries,
    required this.nutrition,
    required this.onDateChanged,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final planner = context.read<MealPlannerProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => onDateChanged(date.subtract(const Duration(days: 1))),
            ),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: AppTypography.h3(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => onDateChanged(date.add(const Duration(days: 1))),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _NutritionSummary(nutrition: nutrition, title: 'สารอาหารวันนี้'),
        const SizedBox(height: AppSpacing.lg),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyState(emoji: '🍽️', message: 'ยังไม่มีมื้ออาหารในวันนี้'),
          )
        else
          ...entries.map((e) {
            final recipe = recipes.cast<Recipe?>().firstWhere(
                  (r) => r?.id == e.recipeId,
                  orElse: () => null,
                );
            return _MealEntryTile(
              mealType: e.mealType,
              recipeName: recipe?.name ?? 'ไม่พบสูตร',
              onTap: recipe != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailScreen(recipe: recipe)),
                      )
                  : null,
              onDelete: () => planner.removeEntry(e.id),
            );
          }),
      ],
    );
  }
}

class _WeeklyView extends StatelessWidget {
  final DateTime weekStart;
  final List<MealPlanEntry> entries;
  final NutritionInfo nutrition;
  final List<Recipe> recipes;

  const _WeeklyView({
    required this.weekStart,
    required this.entries,
    required this.nutrition,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayNames = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 100),
      children: [
        Text(
          'สัปดาห์ ${weekStart.day}/${weekStart.month} - ${weekStart.add(const Duration(days: 6)).day}/${weekStart.add(const Duration(days: 6)).month}',
          style: AppTypography.h3(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.md),
        _NutritionSummary(nutrition: nutrition, title: 'สารอาหารสัปดาห์นี้'),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final dayEntries = entries.where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day).toList();
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppTheme.surf(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppTheme.div(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                title: Text(
                  '${weekdayNames[i]}  ·  ${day.day}/${day.month}',
                  style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)),
                ),
                subtitle: Text('${dayEntries.length} มื้อ', style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.txtSecondary(context)),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MonthlyView extends StatelessWidget {
  final int month;
  final int year;
  final List<MealPlanEntry> entries;
  final List<Recipe> recipes;

  const _MonthlyView({
    required this.month,
    required this.year,
    required this.entries,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final monthNames = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 100),
      children: [
        Text(
          '${monthNames[month]} $year',
          style: AppTypography.h3(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('รวม ${entries.length} มื้อในเดือนนี้', style: AppTypography.body(color: AppTheme.txtSecondary(context))),
        const SizedBox(height: AppSpacing.lg),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyState(emoji: '📅', message: 'ยังไม่มีมื้ออาหารในเดือนนี้'),
          )
        else
          ...entries.map((e) {
            final recipe = recipes.cast<Recipe?>().firstWhere(
                  (r) => r?.id == e.recipeId,
                  orElse: () => null,
                );
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.surf(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppTheme.div(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Text(e.mealType.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(recipe?.name ?? 'ไม่พบสูตร', style: AppTypography.body(color: AppTheme.txtPrimary(context))),
                  subtitle: Text(
                    '${e.date.day}/${e.date.month} · ${e.mealType.label}',
                    style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  final NutritionInfo nutrition;
  final String title;

  const _NutritionSummary({required this.nutrition, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppTheme.primLight(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodyStrong(color: AppTheme.prim(context))),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutItem('🔥', '${nutrition.calories}', 'kcal'),
              _NutItem('💪', '${nutrition.protein.toStringAsFixed(0)}g', 'โปรตีน'),
              _NutItem('🧈', '${nutrition.fat.toStringAsFixed(0)}g', 'ไขมัน'),
              _NutItem('🍞', '${nutrition.carbs.toStringAsFixed(0)}g', 'คาร์บ'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _NutItem(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        Text(value, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 14)),
        Text(label, style: AppTypography.caption(color: AppTheme.txtSecondary(context)).copyWith(fontSize: 10)),
      ],
    );
  }
}

class _MealEntryTile extends StatelessWidget {
  final MealType mealType;
  final String recipeName;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _MealEntryTile({
    required this.mealType,
    required this.recipeName,
    this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.surf(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.div(context)),
        boxShadow: AppShadows.softFor(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppTheme.primLight(context), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Center(child: Text(mealType.emoji, style: const TextStyle(fontSize: 20))),
          ),
          title: Text(recipeName, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
          subtitle: Text(mealType.label, style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppTheme.txtSecondary(context)),
            onPressed: onDelete,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
