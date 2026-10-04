import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/recipe_provider.dart';
import '../../models/recipe.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/add_to_folder_sheet.dart';
import '../recipe/detail_screen.dart';

/// ระบบ Favorite — บันทึกสูตรโปรด, โฟลเดอร์, แชร์, ดาวน์โหลด
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final favorites = recipeProvider.favoriteRecipes;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('สูตรโปรด'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ทั้งหมด'),
              Tab(text: 'โฟลเดอร์'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AllFavoritesTab(favorites: favorites),
            _FoldersTab(
              favProvider: favProvider,
              recipeProvider: recipeProvider,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllFavoritesTab extends StatelessWidget {
  final List<Recipe> favorites;

  const _AllFavoritesTab({required this.favorites});

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const EmptyState(
        emoji: '🤍',
        message: 'ยังไม่มีเมนูที่บันทึกไว้',
        description: 'แตะไอคอนหัวใจที่เมนูโปรดของคุณ\nแล้วมันจะมาปรากฏที่นี่',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final recipe = favorites[index];
        return RecipeCard(
          recipe: recipe,
          onAddToFolder: () => showAddToFolderSheet(context, recipe: recipe),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(recipe: recipe)),
          ),
        );
      },
    );
  }
}

class _FoldersTab extends StatelessWidget {
  final FavoriteProvider favProvider;
  final RecipeProvider recipeProvider;

  const _FoldersTab({required this.favProvider, required this.recipeProvider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppButton.outline(
          label: 'สร้างโฟลเดอร์ใหม่',
          icon: Icons.create_new_folder_outlined,
          onPressed: () => _createFolder(context),
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (favProvider.folders.isEmpty)
          const EmptyState(emoji: '📁', message: 'ยังไม่มีโฟลเดอร์')
        else
          ...favProvider.folders.map((folder) {
            final recipes = favProvider.recipesInFolder(
              folder.id,
              recipeProvider,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.surf(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppTheme.div(context)),
                boxShadow: AppShadows.softFor(context),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primLight(context),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              folder.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                folder.name,
                                style: AppTypography.bodyStrong(
                                  color: AppTheme.txtPrimary(context),
                                ),
                              ),
                              Text(
                                '${recipes.length} เมนู',
                                style: AppTypography.caption(
                                  color: AppTheme.txtSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'ลบโฟลเดอร์',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.error(context),
                          ),
                          onPressed: () => _confirmDeleteFolder(
                            context,
                            favProvider,
                            folder.id,
                            folder.name,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => showPickFavoriteForFolderSheet(
                          context,
                          folderId: folder.id,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('เพิ่มสูตรโปรด'),
                      ),
                    ),
                  ),
                  if (recipes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base,
                        0,
                        AppSpacing.base,
                        AppSpacing.base,
                      ),
                      child: Text(
                        'ยังไม่มีสูตรในโฟลเดอร์นี้ — กด "เพิ่มสูตรโปรด" แล้วเลือกจากหัวใจที่บันทึกไว้',
                        style: AppTypography.body(
                          color: AppTheme.txtSecondary(context),
                        ),
                      ),
                    )
                  else
                    ...recipes.map((recipe) {
                      return ListTile(
                        title: Text(
                          recipe.name,
                          style: AppTypography.body(
                            color: AppTheme.txtPrimary(context),
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final ok = await favProvider.removeRecipeFromFolder(
                              folder.id,
                              recipe.id,
                            );
                            if (!context.mounted || ok) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('เอาออกจากโฟลเดอร์ไม่สำเร็จ'),
                              ),
                            );
                          },
                          child: Text(
                            'เอาออก',
                            style: TextStyle(color: AppTheme.error(context)),
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(recipe: recipe),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    FavoriteProvider favProvider,
    String folderId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ลบโฟลเดอร์ $name?'),
        content: const Text('สูตรในโฟลเดอร์จะไม่ถูกลบออกจากรายการโปรด'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'ลบ',
              style: TextStyle(color: AppTheme.error(dialogContext)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await favProvider.deleteFolder(folderId);
    }
  }

  void _createFolder(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('สร้างโฟลเดอร์'),
        content: AppTextField(controller: controller, hint: 'ชื่อโฟลเดอร์'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FavoriteProvider>().createFolder(
                  controller.text.trim(),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );
  }
}
