import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/recipe_image_picker.dart';

/// แก้ไขสูตรอาหาร
class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;
  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late TextEditingController _nameController;
  late TextEditingController _tipsController;
  late TextEditingController _cookTimeController;
  XFile? _newImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _tipsController = TextEditingController(text: widget.recipe.tips ?? '');
    _cookTimeController = TextEditingController(text: '${widget.recipe.cookTimeMinutes}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tipsController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขสูตร'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('บันทึก', style: TextStyle(color: AppTheme.prim(context), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          RecipeImagePicker(
            currentImageUrl: widget.recipe.imageUrl,
            onChanged: (file) => _newImage = file,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('ข้อมูลพื้นฐาน', style: AppTypography.h2(color: AppTheme.txtPrimary(context))),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'ชื่อเมนู', controller: _nameController),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'เวลาปรุง (นาที)',
            controller: _cookTimeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'เคล็ดลับ', controller: _tipsController, maxLines: 3),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<RecipeProvider>();
    final cookTime = int.tryParse(_cookTimeController.text) ?? widget.recipe.cookTimeMinutes;
    final updated = widget.recipe.copyWith(
      name: _nameController.text.trim(),
      cookTimeMinutes: cookTime,
      tips: _tipsController.text.trim().isEmpty ? null : _tipsController.text.trim(),
    );

    var error = await provider.updateRecipe(updated);
    if (error == null && _newImage != null) {
      error = await provider.updateRecipeImage(widget.recipe.id, _newImage!);
      // อัปโหลดสำเร็จแล้ว ถ้ากดบันทึกอีกรอบ (เช่นหลังแก้ error อื่น) ไม่ต้องอัปโหลดซ้ำ
      if (error == null) _newImage = null;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('แก้ไขสูตรเรียบร้อย')),
    );
  }
}
