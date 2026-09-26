import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/ingredient.dart';
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
import '../../widgets/common/login_required.dart';
import '../../widgets/recipe_image_picker.dart';

/// ฟอร์มสูตรอาหาร — ไม่ส่ง [recipe] = เพิ่มสูตรใหม่, ส่งมา = แก้ไขสูตรนั้น (เฉพาะเจ้าของสูตร)
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

  String _category = 'อาหารจานเดียว';
  String _country = 'ไทย';
  String _difficulty = 'ง่าย';
  bool _isSaving = false;
  int _prepTime = 10;
  int _cookTime = 20;
  int _servings = 2;
  final List<String> _selectedDietTags = [];

  final List<_IngredientControllers> _ingredientControllers = [_IngredientControllers()];

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
    _category = recipe.category;
    _country = recipe.country;
    _difficulty = recipe.difficulty;
    _prepTime = recipe.prepTimeMinutes;
    _cookTime = recipe.cookTimeMinutes;
    _servings = recipe.servings;
    _selectedDietTags.addAll(recipe.dietTags);

    // สูตรเก่าบางสูตรมีแต่วัตถุดิบแบบข้อความ — ใส่ทั้งบรรทัดไว้ในช่องชื่อวัตถุดิบ
    final items = recipe.ingredientItems.isNotEmpty
        ? recipe.ingredientItems
        : recipe.ingredients.map((i) => IngredientItem(name: i, amount: '', unit: '')).toList();
    if (items.isNotEmpty) {
      for (final c in _ingredientControllers) {
        c.dispose();
      }
      _ingredientControllers
        ..clear()
        ..addAll(items.map((i) => _IngredientControllers(amount: i.amount, unit: i.unit, name: i.name)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _tipsController.dispose();
    _platingController.dispose();
    _stepsController.dispose();
    for (final c in _ingredientControllers) {
      c.dispose();
    }
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
          message: _isEditing ? 'เข้าสู่ระบบก่อนแก้ไขสูตรอาหาร' : 'เข้าสู่ระบบก่อนเพิ่มสูตรอาหาร',
          description: 'สูตรที่เพิ่มจะผูกกับบัญชีของคุณ\nแก้ไขหรือลบได้ภายหลัง',
          actionLabel: 'เข้าสู่ระบบ',
          onAction: () => goToLogin(Navigator.of(context)),
        ),
      );
    }
    if (_isEditing && auth.currentUser?.id != widget.recipe!.uploaderId) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyState(emoji: '🔒', message: 'แก้ไขได้เฉพาะสูตรที่คุณเพิ่มเอง'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xxl),
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
                        style: AppTypography.body(color: AppTheme.txtSecondary(context)),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _emojiController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true, hintText: '🍽️'),
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
                  validator: (v) => v?.trim().isEmpty == true ? 'กรุณากรอกชื่อเมนู' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _Dropdown('ประเภท', _category, recipeProvider.categories.where((c) => c != 'ทั้งหมด').toList(),
                    (v) => setState(() => _category = v!)),
                const SizedBox(height: AppSpacing.md),
                _Dropdown('ประเทศ', _country, recipeProvider.countries.where((c) => c != 'ทั้งหมด').toList(),
                    (v) => setState(() => _country = v!)),
              ],
            ),
            _FormSection(
              title: 'รายละเอียดการทำ',
              children: [
                _Dropdown('ความยาก', _difficulty, AppConstants.difficulties, (v) => setState(() => _difficulty = v!)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _NumberField('เตรียม (นาที)', _prepTime, (v) => _prepTime = v)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _NumberField('ปรุง (นาที)', _cookTime, (v) => _cookTime = v)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _NumberField('เสิร์ฟ', _servings, (v) => _servings = v)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('แท็กโภชนาการ', style: AppTypography.bodyStrong(color: AppTheme.txtPrimary(context))),
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
                ..._ingredientControllers.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _IngredientRow(
                        index: e.key,
                        controllers: e.value,
                        onRemove: _ingredientControllers.length > 1
                            ? () => setState(() {
                                  _ingredientControllers.removeAt(e.key).dispose();
                                })
                            : null,
                      ),
                    )),
                AppButton.ghost(
                  label: 'เพิ่มวัตถุดิบ',
                  icon: Icons.add_rounded,
                  fullWidth: false,
                  size: AppButtonSize.small,
                  onPressed: () => setState(() => _ingredientControllers.add(_IngredientControllers())),
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
                  validator: (v) => v?.trim().isEmpty == true ? 'กรุณากรอกขั้นตอน' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _tipsController, label: 'เคล็ดลับ', hint: 'ไม่บังคับ'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _platingController, label: 'วิธีจัดจาน', hint: 'ไม่บังคับ'),
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

    setState(() => _isSaving = true);
    try {
      await _submit();
    } catch (_) {
      // error ที่ไม่ได้มาจาก API (เช่น อ่านไฟล์รูปที่เลือกไว้ไม่ได้แล้ว) — แจ้งแล้วให้ลองใหม่ได้ แทนที่ปุ่มจะหมุนค้าง
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit() async {
    final provider = context.read<RecipeProvider>();
    final steps = _stepsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final items = _ingredientControllers
        .map((c) => c.toItem())
        .where((i) => i.name.trim().isNotEmpty)
        .toList();

    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim().isEmpty ? '🍽️' : _emojiController.text.trim();
    final tips = _tipsController.text.trim().isEmpty ? null : _tipsController.text.trim();
    final platingTips = _platingController.text.trim().isEmpty ? null : _platingController.text.trim();

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
          ingredients: items.map((i) => i.display).toList(),
          ingredientItems: items,
          tips: tips,
          platingTips: platingTips,
          dietTags: List.of(_selectedDietTags),
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
        items: items,
        tips: tips,
        platingTips: platingTips,
        dietTags: _selectedDietTags,
        image: _image,
      );
      error = result.error;
      imageError = result.imageError;
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
          Text(title, style: AppTypography.h2(color: AppTheme.txtPrimary(context))),
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
      // ค่าปัจจุบันต้องอยู่ในตัวเลือกเสมอ ไม่งั้น DropdownButton จะ assert (เช่น หมวดของสูตรที่กำลังแก้ไม่อยู่ในรายการ)
      items: [if (!items.contains(value)) value, ...items]
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
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

/// เก็บ TextEditingController ของแถววัตถุดิบแต่ละแถว — คงค่าที่พิมพ์ไว้ตลอดแม้ parent rebuild
class _IngredientControllers {
  final TextEditingController amount;
  final TextEditingController unit;
  final TextEditingController name;

  _IngredientControllers({String amount = '', String unit = 'กรัม', String name = ''})
      : amount = TextEditingController(text: amount),
        unit = TextEditingController(text: unit),
        name = TextEditingController(text: name);

  IngredientItem toItem() => IngredientItem(name: name.text, amount: amount.text, unit: unit.text);

  void dispose() {
    amount.dispose();
    unit.dispose();
    name.dispose();
  }
}

class _IngredientRow extends StatelessWidget {
  final int index;
  final _IngredientControllers controllers;
  final VoidCallback? onRemove;

  const _IngredientRow({
    required this.index,
    required this.controllers,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controllers.amount,
            decoration: const InputDecoration(hintText: 'ปริมาณ', isDense: true),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextFormField(
            controller: controllers.unit,
            decoration: const InputDecoration(hintText: 'หน่วย', isDense: true),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controllers.name,
            decoration: InputDecoration(hintText: 'วัตถุดิบ ${index + 1}', isDense: true),
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'ลบวัตถุดิบนี้',
            icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppTheme.error(context)),
            onPressed: onRemove,
          ),
      ],
    );
  }
}
