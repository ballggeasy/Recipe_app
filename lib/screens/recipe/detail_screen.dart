import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/nutrition.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/recipe_image.dart';
import '../../widgets/rating_display.dart';
import '../../widgets/source_badge.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/review/review_card.dart';
import '../../widgets/comment/comment_tile.dart';
import 'cooking_mode_screen.dart';
import 'edit_recipe_screen.dart';

/// รายละเอียดสูตรอาหาร — ครบทุกฟีเจอร์ demo
class DetailScreen extends StatefulWidget {
  final Recipe recipe;
  const DetailScreen({super.key, required this.recipe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _imageIndex = 0;

  Recipe get recipe {
    return context.watch<RecipeProvider>().getById(widget.recipe.id) ?? widget.recipe;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewProvider>().loadForRecipe(widget.recipe.id);
      context.read<CommentProvider>().loadForRecipe(widget.recipe.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final commentProvider = context.watch<CommentProvider>();
    final favProvider = context.read<FavoriteProvider>();
    final auth = context.watch<AuthProvider>();
    final isFav = provider.isFavorite(recipe.id);
    final reviews = reviewProvider.getReviewsForRecipe(recipe.id);
    final comments = commentProvider.getTopLevelComments(recipe.id);
    final currentUserId = auth.currentUser?.id;
    final userName = auth.currentUser?.name ?? 'ผู้เยี่ยมชม';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.bg(context),
            foregroundColor: AppTheme.txtPrimary(context),
            elevation: 0,
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditRecipeScreen(recipe: recipe)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () {
                    final link = favProvider.shareRecipe(recipe);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('แชร์ (mock): $link')),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundIconButton(
                  icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFav ? AppTheme.error(context) : null,
                  onTap: () => provider.toggleFavorite(recipe.id),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: _RoundIconButton(
                  icon: Icons.more_vert_rounded,
                  onTap: () => _showMoreMenu(context, provider, favProvider),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageGallery(
                recipe: recipe,
                index: _imageIndex,
                onIndexChanged: (i) => setState(() => _imageIndex = i),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SourceBadge(recipe: recipe),
                  const SizedBox(height: AppSpacing.md),
                  Text(recipe.name, style: AppTypography.display(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 26)),
                  const SizedBox(height: AppSpacing.sm),
                  RatingDisplay(rating: recipe.rating, reviewCount: recipe.reviewCount, fontSize: 13.5, starSize: 16),
                  const SizedBox(height: AppSpacing.base),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _InfoTag(icon: Icons.public_rounded, label: recipe.country),
                      _InfoTag(icon: Icons.timer_outlined, label: 'เตรียม ${recipe.prepTimeMinutes} นาที'),
                      _InfoTag(icon: Icons.access_time_rounded, label: 'ปรุง ${recipe.cookTimeMinutes} นาที'),
                      _InfoTag(icon: Icons.schedule_rounded, label: 'รวม ${recipe.totalTimeMinutes} นาที'),
                      _InfoTag(icon: Icons.bar_chart_rounded, label: recipe.difficulty),
                      _InfoTag(icon: Icons.restaurant_rounded, label: '${recipe.servings} เสิร์ฟ'),
                      _InfoTag(icon: Icons.category_outlined, label: recipe.category),
                      if (recipe.season != 'ตลอดปี') _InfoTag(icon: Icons.wb_sunny_outlined, label: recipe.season),
                      ...recipe.dietTags.map((t) => _InfoTag(icon: Icons.local_offer_outlined, label: t)),
                    ],
                  ),
                  if (recipe.videoUrl != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const _VideoPlaceholder(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'ส่วนผสม'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppTheme.surf(context),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppTheme.div(context)),
                    ),
                    child: Column(
                      children: [
                        if (recipe.ingredientItems.isNotEmpty)
                          ...recipe.ingredientItems.asMap().entries.map((e) => _IngredientRow(
                                item: e.value,
                                showDivider: e.key != recipe.ingredientItems.length - 1,
                              ))
                        else
                          ...recipe.ingredients.asMap().entries.map((e) => _IngredientRow(
                                text: e.value,
                                showDivider: e.key != recipe.ingredients.length - 1,
                              )),
                      ],
                    ),
                  ),
                  if (recipe.tips != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'เคล็ดลับ'),
                    const SizedBox(height: AppSpacing.sm),
                    _TipBox(text: recipe.tips!, icon: Icons.lightbulb_outline_rounded),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'ขั้นตอนการทำ'),
                  const SizedBox(height: AppSpacing.md),
                  ...recipe.steps.asMap().entries.map((e) => _StepRow(number: e.key + 1, text: e.value)),
                  if (recipe.platingTips != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'วิธีจัดจาน'),
                    const SizedBox(height: AppSpacing.sm),
                    _TipBox(text: recipe.platingTips!, icon: Icons.restaurant_menu_rounded),
                  ],
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(title: 'ข้อมูลโภชนาการ (ต่อ 1 เสิร์ฟ)'),
                    const SizedBox(height: AppSpacing.md),
                    _NutritionGrid(nutrition: recipe.nutrition!),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'รีวิว (${reviews.length})',
                    actionLabel: 'เขียนรีวิว',
                    onAction: () => _showAddReviewDialog(context, userName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (reviews.isEmpty)
                    Text('ยังไม่มีรีวิว', style: AppTypography.body(color: AppTheme.txtSecondary(context)))
                  else
                    ...reviews.map((r) => ReviewCard(
                          review: r,
                          isLiked: r.likedBy(currentUserId),
                          onLike: () => reviewProvider.toggleLike(r.id),
                          onReport: () {
                            reviewProvider.reportReview(r.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('รายงานรีวิวแล้ว')),
                            );
                          },
                          onReply: () => _showReplyDialog(context, r.id, userName),
                        )),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'ความคิดเห็น (${comments.length})',
                    actionLabel: 'แสดงความคิดเห็น',
                    onAction: () => _showAddCommentDialog(context, userName),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (comments.isEmpty)
                    Text('ยังไม่มีความคิดเห็น', style: AppTypography.body(color: AppTheme.txtSecondary(context)))
                  else
                    ...comments.map((c) => CommentTile(
                          comment: c,
                          onReply: () => _showAddCommentDialog(context, userName, parentId: c.id),
                          onDelete: () => commentProvider.deleteComment(recipe.id, c.id),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            border: Border(top: BorderSide(color: AppTheme.div(context))),
          ),
          child: AppButton.primary(
            label: 'เริ่มทำอาหาร',
            icon: Icons.play_arrow_rounded,
            onPressed: recipe.steps.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CookingModeScreen(recipe: recipe)),
                    ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, RecipeProvider provider, FavoriteProvider favProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('ดาวน์โหลดสูตร'),
                onTap: () {
                  Navigator.pop(ctx);
                  final file = favProvider.downloadRecipe(recipe);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ดาวน์โหลด (mock): $file')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppTheme.error(context)),
                title: Text('ลบสูตร', style: TextStyle(color: AppTheme.error(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.deleteRecipe(recipe.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, String userName) {
    final controller = TextEditingController();
    double rating = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('เขียนรีวิว'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppTheme.star(ctx),
                    ),
                    onPressed: () => setState(() => rating = i + 1.0),
                  );
                }),
              ),
              AppTextField(controller: controller, maxLines: 3, hint: 'เขียนรีวิวของคุณ...'),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('แนบรูป (placeholder)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            TextButton(
              onPressed: () {
                context.read<ReviewProvider>().addReview(
                      recipeId: recipe.id,
                      rating: rating,
                      content: controller.text.trim(),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('ส่ง'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String reviewId, String userName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ตอบกลับรีวิว'),
        content: AppTextField(controller: controller, maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              context.read<ReviewProvider>().addReply(reviewId, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('ส่ง'),
          ),
        ],
      ),
    );
  }

  void _showAddCommentDialog(BuildContext context, String userName, {String? parentId}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parentId != null ? 'ตอบกลับ' : 'แสดงความคิดเห็น'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              maxLines: 3,
              hint: 'พิมพ์ความคิดเห็น... ใช้ @ชื่อ เพื่อ mention',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton(icon: const Text('😊', style: TextStyle(fontSize: 20)), onPressed: () {
                  controller.text += ' 👍';
                }),
                const IconButton(icon: Icon(Icons.image_outlined), onPressed: null),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              final mentions = RegExp(r'@(\S+)').allMatches(text).map((m) => m.group(1)!).toList();
              context.read<CommentProvider>().addComment(
                    recipeId: recipe.id,
                    content: text,
                    parentId: parentId,
                    mentions: mentions,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('ส่ง'),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surf(context).withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: iconColor ?? AppTheme.txtPrimary(context)),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final Recipe recipe;
  final int index;
  final ValueChanged<int> onIndexChanged;

  const _ImageGallery({required this.recipe, required this.index, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    final images = recipe.allImages;
    if (images.length <= 1) {
      return RecipeImage(recipe: recipe, emojiSize: 88);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RecipeImage(recipe: recipe, emojiSize: 88),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length.clamp(1, 5), (i) {
              return GestureDetector(
                onTap: () => onIndexChanged(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index ? Colors.white : Colors.white54,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.primLight(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.div(context)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline_rounded, size: 48, color: AppTheme.prim(context)),
            const SizedBox(height: AppSpacing.sm),
            Text('วิดีโอการทำอาหาร (Placeholder)', style: AppTypography.body(color: AppTheme.txtSecondary(context))),
          ],
        ),
      ),
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  final NutritionInfo nutrition;

  const _NutritionGrid({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🔥', '${nutrition.calories}', 'แคลอรี'),
      ('💪', '${nutrition.protein}g', 'โปรตีน'),
      ('🧈', '${nutrition.fat}g', 'ไขมัน'),
      ('🍞', '${nutrition.carbs}g', 'คาร์บ'),
      ('🍬', '${nutrition.sugar}g', 'น้ำตาล'),
      ('🧂', '${nutrition.sodium}mg', 'โซเดียม'),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        return Container(
          width: 96,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppTheme.div(context)),
          ),
          child: Column(
            children: [
              Text(item.$1, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(item.$2, style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 14)),
              Text(item.$3, style: AppTypography.caption(color: AppTheme.txtSecondary(context)).copyWith(fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primLight(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.prim(context)),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption(color: AppTheme.prim(context)).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String? text;
  final IngredientItem? item;
  final bool showDivider;
  const _IngredientRow({this.text, this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final display = text ?? item!.display;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: AppTheme.prim(context), shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(display, style: AppTypography.body(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 14.5))),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: AppTheme.div(context)),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.surf(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppTheme.div(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: AppTheme.prim(context), shape: BoxShape.circle),
              child: Center(
                child: Text('$number', style: AppTypography.bodyStrong(color: Colors.white).copyWith(fontSize: 12)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: AppTypography.body(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 14.5, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _TipBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.secondaryMuted(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.secondary(context)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(color: AppTheme.txtPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}
