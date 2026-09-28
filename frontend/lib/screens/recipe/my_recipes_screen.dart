import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/recipe_image.dart';
import 'detail_screen.dart';
import 'recipe_form_screen.dart';

/// สูตรที่ผู้ใช้เพิ่มเอง — แตะเพื่อดู, กดดินสอเพื่อแก้ไข
class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final mine = context
        .watch<RecipeProvider>()
        .allRecipes
        .where((r) => userId != null && r.uploaderId == userId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('สูตรของฉัน')),
      body: mine.isEmpty
          ? EmptyState(
              emoji: '📝',
              message: 'ยังไม่มีสูตรที่คุณเพิ่ม',
              description: 'สูตรที่เพิ่มจะแสดงที่นี่\nแก้ไขหรือลบได้ตลอด',
              actionLabel: 'เพิ่มสูตรอาหาร',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: mine.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final recipe = mine[index];
                return Material(
                  color: AppTheme.surf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: BorderSide(color: AppTheme.div(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: RecipeImage(
                        recipe: recipe,
                        emojiSize: 26,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    title: Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)),
                    ),
                    subtitle: Text(
                      '${recipe.category} · ${recipe.totalTimeMinutes} นาที',
                      style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
                    ),
                    trailing: IconButton(
                      tooltip: 'แก้ไข ${recipe.name}',
                      icon: Icon(Icons.edit_outlined, color: AppTheme.prim(context)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: recipe)),
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailScreen(recipe: recipe)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
