import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/recipe_image_picker.dart';

/// ฟอร์มสูตรอาหาร — ไม่ส่ง [recipe] = เพิ่มสูตรใหม่, ส่งมา = แก้ไขสูตรนั้นทุกช่อง (เฉพาะเจ้าของสูตร)
class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  /// ส่งตัวเลือกรูปปลอมเข้ามาได้ใน test (ส่งต่อให้ [RecipeImagePicker]) — ปกติใช้คลังรูปของเครื่อง
  @visibleForTesting
  final Future<XFile?> Function()? pickImage;

  const RecipeFormScreen({super.key, this.recipe, this.pickImage});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🍽️');
  final _tipsController = TextEditingController();
  final _platingController = TextEditingController();
  final _stepsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _videoController = TextEditingController();

  String _category = 'อาหารจานเดียว';
  String _country = 'ไทย';
  String _difficulty = 'ง่าย';
  bool _isSaving = false;
  int _prepTime = 10;
  int _cookTime = 20;
  int _servings = 2;
  final List<String> _selectedDietTags = [];
  XFile? _image; // รูปที่เพิ่งเลือก — อัปโหลดตอนกดบันทึก (null = ใช้รูปเดิม)

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe == null) return;

    _nameController.text = recipe.name;
    _emojiController.text = recipe.emoji;
    _tipsController.text = recipe.tips ?? '';
    _platingController.text = recipe.platingTips ?? '';
    _stepsController.text = recipe.steps.join('\n');
    _videoController.text = recipe.videoUrl ?? '';
    _category = recipe.category;
    _country = recipe.country;
    _difficulty = recipe.difficulty;
    _prepTime = recipe.prepTimeMinutes;
    _cookTime = recipe.cookTimeMinutes;
    _servings = recipe.servings;
    _selectedDietTags.addAll(recipe.dietTags);

    // ส่วนผสมเก็บเป็นข้อความบรรทัดละอย่าง — สูตรเก่าที่มีแต่แบบแยกช่อง (ปริมาณ/หน่วย/ชื่อ) แปลงเป็นข้อความให้
    _ingredientsController.text =
        (recipe.ingredients.isNotEmpty
                ? recipe.ingredients
                : recipe.ingredientItems.map((i) => i.display))
            .join('\n');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _tipsController.dispose();
    _platingController.dispose();
    _stepsController.dispose();
    _videoController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final auth = context.watch<AuthProvider>();
    final title = _isEditing ? 'แก้ไขสูตรอาหาร' : 'เพิ่มสูตรอาหาร';

    // กันไว้อีกชั้นเผื่อมีทางเข้าหน้านี้โดยไม่ผ่านปุ่มที่เช็คแล้ว — ไม่ให้กรอกทั้งฟอร์มแล้วค่อยโดน 401/403 จาก backend
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          emoji: '🔒',
          message: _isEditing
              ? 'เข้าสู่ระบบก่อนแก้ไขสูตรอาหาร'
              : 'เข้าสู่ระบบก่อนเพิ่มสูตรอาหาร',
          description: 'สูตรที่เพิ่มจะผูกกับบัญชีของคุณ\nแก้ไขหรือลบได้ภายหลัง',
          actionLabel: 'เข้าสู่ระบบ',
          onAction: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<AuthProvider>().goToLogin();
          },
        ),
      );
    }
    if (_isEditing && auth.currentUser?.id != widget.recipe!.uploaderId) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyState(
          emoji: '🔒',
          message: 'แก้ไขได้เฉพาะสูตรที่คุณเพิ่มเอง',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.base,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _FormSection(
              title: 'รูปภาพ',
              children: [
                RecipeImagePicker(
                  currentImageUrl: widget.recipe?.imageUrl,
                  onChanged: (file) => _image = file,
                  pickImage: widget.pickImage,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'อีโมจิประจำเมนู (ใช้แทนรูปเมื่อไม่มีรูป)',
                        style: AppTypography.body(
                          color: AppTheme.txtSecondary(context),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _emojiController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '🍽️',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _FormSection(
              title: 'ข้อมูลพื้นฐาน',
              children: [
                AppTextField(
                  label: 'ชื่อเมนู *',
                  controller: _nameController,
                  hint: 'เช่น ต้มยำกุ้งน้ำข้น',
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'กรุณากรอกชื่อเมนู' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _Dropdown(
                  'ประเภท',
                  _category,
                  recipeProvider.categories
                      .where((c) => c != 'ทั้งหมด')
                      .toList(),
                  (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                _Dropdown(
                  'ประเทศ',
                  _country,
                  recipeProvider.countries
                      .where((c) => c != 'ทั้งหมด')
                      .toList(),
                  (v) => setState(() => _country = v!),
                ),
              ],
            ),
            _FormSection(
              title: 'รายละเอียดการทำ',
              children: [
                _Dropdown(
                  'ความยาก',
                  _difficulty,
                  AppConstants.difficulties,
                  (v) => setState(() => _difficulty = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        'เตรียม (นาที)',
                        _prepTime,
                        (v) => _prepTime = v,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _NumberField(
                        'ปรุง (นาที)',
                        _cookTime,
                        (v) => _cookTime = v,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _NumberField(
                        'เสิร์ฟ',
                        _servings,
                        (v) => _servings = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'แท็กโภชนาการ',
                  style: AppTypography.bodyStrong(
                    color: AppTheme.txtPrimary(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: AppConstants.dietTags.map((tag) {
                    final selected = _selectedDietTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (s) => setState(() {
                        if (s) {
                          _selectedDietTags.add(tag);
                        } else {
                          _selectedDietTags.remove(tag);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
            _FormSection(
              title: 'ส่วนผสม',
              children: [
                AppTextField(
                  controller: _ingredientsController,
                  maxLines: 6,
                  hint: 'พิมพ์ 1 บรรทัดต่อ 1 อย่าง เช่น ไก่ 1 กิโลกรัม',
                  label: 'ส่วนผสม (แยกบรรทัด) *',
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'กรุณากรอกส่วนผสม' : null,
                ),
              ],
            ),
            _FormSection(
              title: 'ขั้นตอนการทำ',
              children: [
                AppTextField(
                  controller: _stepsController,
                  maxLines: 6,
                  hint: 'พิมพ์ 1 บรรทัดต่อ 1 ขั้นตอน',
                  label: 'ขั้นตอน (แยกบรรทัด) *',
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'กรุณากรอกขั้นตอน' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _tipsController,
                  label: 'เคล็ดลับ',
                  hint: 'ไม่บังคับ',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _platingController,
                  label: 'วิธีจัดจาน',
                  hint: 'ไม่บังคับ',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _videoController,
                  label: 'ลิงก์วิดีโอ',
                  hint: 'https://... ไม่บังคับ',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.primary(
              label: _isEditing ? 'บันทึกการแก้ไข' : 'บันทึกสูตร',
              icon: Icons.check_rounded,
              onPressed: _save,
              loading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final video = _videoController.text.trim();
    if (video.isNotEmpty &&
        !video.startsWith('https://') &&
        !video.startsWith('http://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลิงก์วิดีโอต้องขึ้นต้นด้วย http:// หรือ https://'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _submit(video);
    } catch (_) {
      // error ที่ไม่ได้มาจาก API (เช่น อ่านไฟล์รูปที่เลือกไว้ไม่ได้แล้ว) — แจ้งแล้วให้ลองใหม่ได้ แทนที่ปุ่มจะหมุนค้าง
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit(String video) async {
    final provider = context.read<RecipeProvider>();
    final steps = _stepsController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final ingredients = _ingredientsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim().isEmpty
        ? '🍽️'
        : _emojiController.text.trim();
    final tips = _tipsController.text.trim().isEmpty
        ? null
        : _tipsController.text.trim();
    final platingTips = _platingController.text.trim().isEmpty
        ? null
        : _platingController.text.trim();

    String? error;
    String? imageError;
    if (widget.recipe case final original?) {
      error = await provider.updateRecipe(
        original.copyWith(
          name: name,
          emoji: emoji,
          category: _category,
          country: _country,
          prepTimeMinutes: _prepTime,
          cookTimeMinutes: _cookTime,
          difficulty: _difficulty,
          servings: _servings,
          steps: steps,
          ingredients: ingredients,
          // ล้างแบบแยกช่องของเดิมทิ้ง ไม่งั้นหน้ารายละเอียด (ซึ่งแสดงแบบแยกช่องก่อน) จะยังโชว์ค่าเก่า
          ingredientItems: const [],
          tips: tips,
          platingTips: platingTips,
          dietTags: List.of(_selectedDietTags),
          // '' = ลบลิงก์ (copyWith ใช้ null แทน "ไม่เปลี่ยน")
          videoUrl: video,
        ),
      );
      if (error == null && _image != null) {
        error = await provider.updateRecipeImage(original.id, _image!);
        // อัปโหลดสำเร็จแล้ว ถ้ากดบันทึกอีกรอบ (เช่นหลังแก้ error อื่น) ไม่ต้องอัปโหลดซ้ำ
        if (error == null) _image = null;
      }
    } else {
      final result = await provider.addRecipe(
        name: name,
        emoji: emoji,
        category: _category,
        country: _country,
        prepTime: _prepTime,
        cookTime: _cookTime,
        difficulty: _difficulty,
        servings: _servings,
        steps: steps,
        ingredients: ingredients,
        tips: tips,
        platingTips: platingTips,
        dietTags: _selectedDietTags,
        videoUrl: video.isEmpty ? null : video,
        image: _image,
      );
      error = result.error;
      imageError = result.imageError;
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // สูตรใหม่ถูกบันทึกแล้วแม้รูปจะอัปโหลดไม่ผ่าน จึงออกจากหน้านี้เสมอ (กันผู้ใช้กดบันทึกซ้ำจนได้สูตรซ้ำ)
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          imageError != null
              ? 'เพิ่มสูตรแล้ว แต่อัปโหลดรูปไม่สำเร็จ ($imageError) — เพิ่มรูปได้ที่หน้าแก้ไขสูตร'
              : _isEditing
              ? 'แก้ไขสูตรเรียบร้อย'
              : 'เพิ่มสูตรเรียบร้อย',
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h2(color: AppTheme.txtPrimary(context)),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown(this.label, this.value, this.items, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      // ค่าปัจจุบันต้องอยู่ในตัวเลือกเสมอ ไม่งั้น DropdownButton จะ assert
      // (เช่น หมวดของสูตรที่กำลังแก้ไม่อยู่ในรายการ หรือรายการสูตรยังโหลดไม่เสร็จ)
      items: [
        if (!items.contains(value)) value,
        ...items,
      ].map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(int.tryParse(v) ?? value),
    );
  }
}
