import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// backend รับรูปไม่เกิน 5 MB — เช็คฝั่ง client ก่อนจะได้บอกผู้ใช้ทันทีโดยไม่ต้องรออัปโหลด
const _maxImageBytes = 5 * 1024 * 1024;

/// เลือกรูปเมนูจากเครื่องพร้อม preview — ใช้ทั้งหน้าเพิ่มและแก้ไขสูตร
///
/// แสดงรูปที่เพิ่งเลือก ถ้ายังไม่เลือกจะแสดง [currentImageUrl] (รูปเดิมของสูตร) หรือ placeholder
/// ไฟล์ที่เลือกจะส่งออกทาง [onChanged] (null = ยกเลิกรูปที่เลือก กลับไปใช้รูปเดิม) แล้วหน้าจอเป็นคนอัปโหลดตอนกดบันทึก
class RecipeImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final ValueChanged<XFile?> onChanged;

  /// ตัวเลือกรูปที่ใช้จริงคือ [ImagePicker.pickImage] — เปิดให้ test ส่งตัวปลอมเข้ามาได้
  @visibleForTesting
  final Future<XFile?> Function()? pickImage;

  const RecipeImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onChanged,
    this.pickImage,
  });

  @override
  State<RecipeImagePicker> createState() => _RecipeImagePickerState();
}

class _RecipeImagePickerState extends State<RecipeImagePicker> {
  Uint8List? _pickedBytes;

  Future<XFile?> _pickFromGallery() =>
      ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);

  Future<void> _pick() async {
    final file = await (widget.pickImage ?? _pickFromGallery)();
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รูปใหญ่เกิน 5 MB กรุณาเลือกรูปอื่น')),
      );
      return;
    }

    setState(() => _pickedBytes = bytes);
    widget.onChanged(file);
  }

  void _clear() {
    setState(() => _pickedBytes = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrent = widget.currentImageUrl?.isNotEmpty == true;
    final hasImage = _pickedBytes != null || hasCurrent;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              button: true,
              label: hasImage ? 'เปลี่ยนรูปเมนู' : 'เลือกรูปเมนู',
              onTap: _pick,
              excludeSemantics: true,
              child: Material(
                color: AppTheme.primLight(context),
                child: InkWell(
                  onTap: _pick,
                  child: _pickedBytes != null
                      ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                      : hasCurrent
                          ? Image.network(
                              widget.currentImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const _Placeholder(),
                            )
                          : const _Placeholder(),
                ),
              ),
            ),
            if (hasImage)
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Row(
                  children: [
                    if (_pickedBytes != null) ...[
                      _OverlayButton(icon: Icons.close_rounded, tooltip: 'ยกเลิกรูปที่เลือก', onPressed: _clear),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    _OverlayButton(icon: Icons.photo_library_outlined, tooltip: 'เปลี่ยนรูปเมนู', onPressed: _pick),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppTheme.prim(context)),
          const SizedBox(height: AppSpacing.sm),
          Text('แตะเพื่อเลือกรูปเมนู', style: AppTypography.bodyStrong(color: AppTheme.prim(context))),
          const SizedBox(height: 2),
          Text('JPG, PNG, WebP ไม่เกิน 5 MB', style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _OverlayButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.surf(context).withValues(alpha: 0.92),
        foregroundColor: AppTheme.txtPrimary(context),
      ),
    );
  }
}
