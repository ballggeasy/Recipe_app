import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            _FoldersTab(favProvider: favProvider, recipeProvider: recipeProvider),
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
            final recipes = favProvider.recipesInFolder(folder.id, recipeProvider);
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.surf(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppTheme.div(context)),
                boxShadow: AppShadows.softFor(context),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primLight(context),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(child: Text(folder.emoji, style: const TextStyle(fontSize: 20))),
                  ),
                  title: Text(folder.name, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
                  subtitle: Text('${recipes.length} เมนู', style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
                  children: recipes.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
                            child: Text(
                              'ยังไม่มีสูตรในโฟลเดอร์นี้',
                              style: AppTypography.body(color: AppTheme.txtSecondary(context)),
                            ),
                          ),
                        ]
                      : recipes.map((recipe) {
                          return ListTile(
                            title: Text(recipe.name, style: AppTypography.body(color: AppTheme.txtPrimary(context))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'คัดลอกลิงก์สูตร',
                                  icon: Icon(Icons.share_outlined, size: 20, color: AppTheme.txtSecondary(context)),
                                  onPressed: () {
                                    final link = favProvider.shareRecipe(recipe);
                                    Clipboard.setData(ClipboardData(text: link));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('คัดลอกลิงก์แล้ว: $link')),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'ดาวน์โหลดสูตร',
                                  icon: Icon(Icons.download_outlined, size: 20, color: AppTheme.txtSecondary(context)),
                                  onPressed: () {
                                    final file = favProvider.downloadRecipe(recipe);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('ดาวน์โหลด (mock): $file')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DetailScreen(recipe: recipe)),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _createFolder(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('สร้างโฟลเดอร์'),
        content: AppTextField(controller: controller, hint: 'ชื่อโฟลเดอร์'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FavoriteProvider>().createFolder(controller.text.trim());
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
