import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/recipe_image.dart';
import '../../widgets/rating_display.dart';
import '../../widgets/source_badge.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/review/review_card.dart';
import '../../widgets/comment/comment_tile.dart';
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
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final commentProvider = context.watch<CommentProvider>();
    final favProvider = context.read<FavoriteProvider>();
    final auth = context.watch<AuthProvider>();
    final isFav = provider.isFavorite(recipe.id);
    final reviews = reviewProvider.getReviewsForRecipe(recipe.id);
    final comments = commentProvider.getTopLevelComments(recipe.id);
    final userName = auth.currentUser?.name ?? 'ผู้เยี่ยมชม';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditRecipeScreen(recipe: recipe)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final link = favProvider.shareRecipe(recipe);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('แชร์ (mock): $link')),
                  );
                },
              ),
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? AppTheme.accentRed : AppTheme.textPrimary),
                onPressed: () => provider.toggleFavorite(recipe.id),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  PopupMenuItem(
                    child: const Text('ดาวน์โหลดสูตร'),
                    onTap: () {
                      final file = favProvider.downloadRecipe(recipe);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ดาวน์โหลด (mock): $file')),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('ลบสูตร'),
                    onTap: () {
                      provider.deleteRecipe(recipe.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageGallery(recipe: recipe, index: _imageIndex, onIndexChanged: (i) => setState(() => _imageIndex = i)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SourceBadge(recipe: recipe),
                  const SizedBox(height: 12),
                  Text(recipe.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  RatingDisplay(rating: recipe.rating, reviewCount: recipe.reviewCount, fontSize: 13.5, starSize: 16),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoTag(icon: Icons.public, label: recipe.country),
                      _InfoTag(icon: Icons.timer_outlined, label: 'เตรียม ${recipe.prepTimeMinutes} นาที'),
                      _InfoTag(icon: Icons.access_time, label: 'ปรุง ${recipe.cookTimeMinutes} นาที'),
                      _InfoTag(icon: Icons.schedule, label: 'รวม ${recipe.totalTimeMinutes} นาที'),
                      _InfoTag(icon: Icons.bar_chart, label: recipe.difficulty),
                      _InfoTag(icon: Icons.restaurant, label: '${recipe.servings} เสิร์ฟ'),
                      _InfoTag(icon: Icons.category_outlined, label: recipe.category),
                      if (recipe.season != 'ตลอดปี') _InfoTag(icon: Icons.wb_sunny_outlined, label: recipe.season),
                      ...recipe.dietTags.map((t) => _InfoTag(icon: Icons.local_offer_outlined, label: t)),
                    ],
                  ),
                  if (recipe.videoUrl != null) ...[
                    const SizedBox(height: 20),
                    _VideoPlaceholder(),
                  ],
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'ส่วนผสม'),
                  const SizedBox(height: 12),
                  if (recipe.ingredientItems.isNotEmpty)
                    ...recipe.ingredientItems.map((i) => _IngredientRow(text: i.display))
                  else
                    ...recipe.ingredients.map((i) => _IngredientRow(text: i)),
                  if (recipe.tips != null) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'เคล็ดลับ'),
                    const SizedBox(height: 8),
                    _TipBox(text: recipe.tips!, icon: Icons.lightbulb_outline),
                  ],
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'ขั้นตอนการทำ'),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map((e) => _StepRow(number: e.key + 1, text: e.value)),
                  if (recipe.platingTips != null) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'วิธีจัดจาน'),
                    const SizedBox(height: 8),
                    _TipBox(text: recipe.platingTips!, icon: Icons.restaurant_menu),
                  ],
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'ข้อมูลโภชนาการ (ต่อ 1 เสิร์ฟ)'),
                    const SizedBox(height: 12),
                    _NutritionGrid(nutrition: recipe.nutrition!),
                  ],
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'รีวิว (${reviews.length})',
                    trailing: TextButton(
                      onPressed: () => _showAddReviewDialog(context, userName),
                      child: const Text('เขียนรีวิว'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (reviews.isEmpty)
                    const Text('ยังไม่มีรีวิว', style: TextStyle(color: AppTheme.textSecondary))
                  else
                    ...reviews.map((r) => ReviewCard(
                          review: r,
                          onLike: () => reviewProvider.toggleLike(r.id),
                          onReport: () {
                            reviewProvider.reportReview(r.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('รายงานรีวิวแล้ว')),
                            );
                          },
                          onReply: () => _showReplyDialog(context, r.id, userName),
                        )),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'ความคิดเห็น (${comments.length})',
                    trailing: TextButton(
                      onPressed: () => _showAddCommentDialog(context, userName),
                      child: const Text('แสดงความคิดเห็น'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (comments.isEmpty)
                    const Text('ยังไม่มีความคิดเห็น', style: TextStyle(color: AppTheme.textSecondary))
                  else
                    ...comments.map((c) => CommentTile(
                          comment: c,
                          onReply: () => _showAddCommentDialog(context, userName, parentId: c.id),
                          onDelete: () => commentProvider.deleteComment(c.id),
                        )),
                ],
              ),
            ),
          ),
        ],
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
                    icon: Icon(i < rating ? Icons.star : Icons.star_border, color: const Color(0xFFE0A33B)),
                    onPressed: () => setState(() => rating = i + 1.0),
                  );
                }),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'เขียนรีวิวของคุณ...'),
              ),
              const SizedBox(height: 8),
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
                      userName: userName,
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
        content: TextField(controller: controller, maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              context.read<ReviewProvider>().addReply(reviewId, userName, controller.text.trim());
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
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'พิมพ์ความคิดเห็น... ใช้ @ชื่อ เพื่อ mention'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(icon: const Text('😊', style: TextStyle(fontSize: 20)), onPressed: () {
                  controller.text += ' 👍';
                }),
                IconButton(icon: const Icon(Icons.image_outlined), onPressed: () {}),
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
                    userName: userName,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 48, color: AppTheme.primary),
            SizedBox(height: 8),
            Text('วิดีโอการทำอาหาร (Placeholder)', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  final dynamic nutrition;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10 * 2) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.surf(context),
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.shadow(context),
              ),
              child: Column(
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.txtPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$3,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.txtSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primLight(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.prim(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.prim(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String text;
  const _IngredientRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.prim(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: AppTheme.txtPrimary(context),
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.prim(context),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.prim(context).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppTheme.txtPrimary(context),
                ),
              ),
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        color: AppTheme.primLight(context),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: AppTheme.prim(context), width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppTheme.prim(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.txtPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
