import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ingredient.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// เพิ่มสูตรอาหารใหม่
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มสูตรอาหาร')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xxl),
          children: [
            _FormSection(
              title: 'รูปภาพ',
              children: [_ImagePickerPlaceholder(emojiController: _emojiController)],
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
            AppButton.primary(label: 'บันทึกสูตร', icon: Icons.check_rounded, onPressed: _save, loading: _isSaving),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<RecipeProvider>();
    final steps = _stepsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final items = _ingredientControllers
        .map((c) => c.toItem())
        .where((i) => i.name.trim().isNotEmpty)
        .toList();

    final error = await provider.addRecipe(
      name: _nameController.text.trim(),
      emoji: _emojiController.text.trim().isEmpty ? '🍽️' : _emojiController.text.trim(),
      category: _category,
      country: _country,
      prepTime: _prepTime,
      cookTime: _cookTime,
      difficulty: _difficulty,
      servings: _servings,
      steps: steps,
      items: items,
      tips: _tipsController.text.trim().isEmpty ? null : _tipsController.text.trim(),
      platingTips: _platingController.text.trim().isEmpty ? null : _platingController.text.trim(),
      dietTags: _selectedDietTags,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เพิ่มสูตรเรียบร้อย')),
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

class _ImagePickerPlaceholder extends StatelessWidget {
  final TextEditingController emojiController;
  const _ImagePickerPlaceholder({required this.emojiController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primLight(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.div(context)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppTheme.prim(context)),
            const SizedBox(height: AppSpacing.sm),
            Text('เพิ่มรูปภาพเมนู (placeholder)', style: AppTypography.body(color: AppTheme.txtSecondary(context))),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: 80,
              child: TextField(
                controller: emojiController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, hintText: '🍽️'),
              ),
            ),
          ],
        ),
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
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
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
