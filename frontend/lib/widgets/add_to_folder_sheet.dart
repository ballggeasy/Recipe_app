import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// ให้ผู้ใช้เลือกโฟลเดอร์เพื่อเก็บสูตร — ถ้ายังไม่ล็อกอินจะบอกให้เข้าสู่ระบบ
Future<void> showAddToFolderSheet(
  BuildContext context, {
  required Recipe recipe,
}) {
  final auth = context.read<AuthProvider>();
  if (!auth.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เข้าสู่ระบบเพื่อจัดสูตรเข้าโฟลเดอร์')),
    );
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddToFolderSheet(recipe: recipe),
  );
}

class _AddToFolderSheet extends StatelessWidget {
  final Recipe recipe;

  const _AddToFolderSheet({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final recipes = context.read<RecipeProvider>();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.surf(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'เพิ่ม "${recipe.name}" เข้าโฟลเดอร์',
                style: AppTypography.h3(color: AppTheme.txtPrimary(context)),
              ),
            ),
            if (fav.folders.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Text(
                  'ยังไม่มีโฟลเดอร์ — สร้างที่แท็บโฟลเดอร์ในหน้าสูตรโปรดก่อน',
                  style: AppTypography.body(
                    color: AppTheme.txtSecondary(context),
                  ),
                ),
              )
            else
              ...fav.folders.map((folder) {
                final alreadyIn = folder.recipeIds.contains(recipe.id);
                return ListTile(
                  leading: Text(
                    folder.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(folder.name),
                  trailing: Icon(
                    alreadyIn
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: alreadyIn
                        ? AppTheme.prim(context)
                        : AppTheme.txtSecondary(context),
                  ),
                  onTap: () async {
                    if (!recipes.isFavorite(recipe.id)) {
                      recipes.toggleFavorite(recipe.id);
                    }
                    final ok = alreadyIn
                        ? await fav.removeRecipeFromFolder(folder.id, recipe.id)
                        : await fav.addRecipeToFolder(folder.id, recipe.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? (alreadyIn
                                    ? 'เอาออกจากโฟลเดอร์ ${folder.name} แล้ว'
                                    : 'เพิ่มเข้าโฟลเดอร์ ${folder.name} แล้ว')
                              : 'บันทึกโฟลเดอร์ไม่สำเร็จ ลองอีกครั้ง',
                        ),
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// เลือกสูตรโปรดที่มีอยู่แล้วเพื่อใส่ในโฟลเดอร์
Future<void> showPickFavoriteForFolderSheet(
  BuildContext context, {
  required String folderId,
}) {
  final auth = context.read<AuthProvider>();
  if (!auth.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เข้าสู่ระบบเพื่อจัดสูตรเข้าโฟลเดอร์')),
    );
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PickFavoriteForFolderSheet(folderId: folderId),
  );
}

class _PickFavoriteForFolderSheet extends StatelessWidget {
  final String folderId;

  const _PickFavoriteForFolderSheet({required this.folderId});

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>();
    final fav = context.watch<FavoriteProvider>();
    final folder = fav.getFolder(folderId);
    final favorites = recipes.favoriteRecipes;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.surf(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'เลือกสูตรโปรดใส่โฟลเดอร์',
                style: AppTypography.h3(color: AppTheme.txtPrimary(context)),
              ),
            ),
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Text(
                  'ยังไม่มีสูตรโปรด — แตะหัวใจที่เมนูก่อน แล้วค่อยใส่โฟลเดอร์',
                  style: AppTypography.body(
                    color: AppTheme.txtSecondary(context),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView(
                  shrinkWrap: true,
                  children: favorites.map((recipe) {
                    final alreadyIn =
                        folder?.recipeIds.contains(recipe.id) ?? false;
                    return ListTile(
                      title: Text(recipe.name),
                      trailing: Icon(
                        alreadyIn
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: alreadyIn
                            ? AppTheme.prim(context)
                            : AppTheme.txtSecondary(context),
                      ),
                      onTap: alreadyIn
                          ? null
                          : () async {
                              final ok = await fav.addRecipeToFolder(
                                folderId,
                                recipe.id,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'เพิ่ม ${recipe.name} เข้าโฟลเดอร์แล้ว'
                                        : 'เพิ่มเข้าโฟลเดอร์ไม่สำเร็จ ลองอีกครั้ง',
                                  ),
                                ),
                              );
                            },
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
