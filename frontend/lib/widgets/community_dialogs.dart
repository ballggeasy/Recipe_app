import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/comment_provider.dart';
import '../providers/review_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/require_login.dart';
import 'common/app_text_field.dart';

const _maxImageBytes = 5 * 1024 * 1024;

Future<void> showReviewComposer(
  BuildContext context, {
  required String recipeId,
}) {
  if (!requireLogin(context, 'เข้าสู่ระบบเพื่อเขียนรีวิว')) {
    return Future.value();
  }
  return showDialog<void>(
    context: context,
    builder: (_) => _ReviewComposer(recipeId: recipeId),
  );
}

Future<void> showCommentComposer(
  BuildContext context, {
  required String recipeId,
  String? parentId,
}) {
  if (!requireLogin(context, 'เข้าสู่ระบบเพื่อแสดงความคิดเห็น')) {
    return Future.value();
  }
  return showDialog<void>(
    context: context,
    builder: (_) => _CommentComposer(recipeId: recipeId, parentId: parentId),
  );
}

class _ReviewComposer extends StatefulWidget {
  final String recipeId;

  const _ReviewComposer({required this.recipeId});

  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<_ReviewComposer> {
  final _controller = TextEditingController();
  double _rating = 5;
  XFile? _image;
  Uint8List? _preview;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final result = await context.read<ReviewProvider>().addReview(
      recipeId: widget.recipeId,
      rating: _rating,
      content: _controller.text.trim(),
      image: _image,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.error != null) {
      _show(result.error!);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (result.imageError != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ส่งรีวิวแล้ว แต่อัปโหลดรูปไม่สำเร็จ')),
      );
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เขียนรีวิว'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  tooltip: 'ให้ ${i + 1} ดาว',
                  icon: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppTheme.star(context),
                  ),
                  onPressed: () => setState(() => _rating = i + 1.0),
                );
              }),
            ),
            AppTextField(
              controller: _controller,
              maxLines: 3,
              hint: 'เขียนรีวิวของคุณ...',
            ),
            const SizedBox(height: AppSpacing.sm),
            _PhotoPicker(
              preview: _preview,
              onPick: _pick,
              onClear: () => setState(() {
                _image = null;
                _preview = null;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'กำลังส่ง...' : 'ส่ง'),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxImageBytes) {
      _show('รูปใหญ่เกิน 5 MB กรุณาเลือกรูปอื่น');
      return;
    }
    setState(() {
      _image = file;
      _preview = bytes;
    });
  }
}

class _CommentComposer extends StatefulWidget {
  final String recipeId;
  final String? parentId;

  const _CommentComposer({required this.recipeId, this.parentId});

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();
  XFile? _image;
  Uint8List? _preview;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _show('กรุณาพิมพ์ความคิดเห็น');
      return;
    }
    setState(() => _sending = true);
    final mentions = RegExp(
      r'@(\S+)',
    ).allMatches(text).map((m) => m.group(1)!).toList();
    final result = await context.read<CommentProvider>().addComment(
      recipeId: widget.recipeId,
      content: text,
      parentId: widget.parentId,
      mentions: mentions,
      image: _image,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.error != null) {
      _show(result.error!);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (result.imageError != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ส่งความคิดเห็นแล้ว แต่อัปโหลดรูปไม่สำเร็จ'),
        ),
      );
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.parentId != null ? 'ตอบกลับ' : 'แสดงความคิดเห็น'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _controller,
              maxLines: 3,
              hint: 'พิมพ์ความคิดเห็น... ใช้ @ชื่อ เพื่อ mention',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton(
                  tooltip: 'ใส่อีโมจิ 👍',
                  icon: const Text('😊', style: TextStyle(fontSize: 20)),
                  onPressed: () => _controller.text = '${_controller.text} 👍',
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PhotoPicker(
                    preview: _preview,
                    onPick: _pick,
                    onClear: () => setState(() {
                      _image = null;
                      _preview = null;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'กำลังส่ง...' : 'ส่ง'),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxImageBytes) {
      _show('รูปใหญ่เกิน 5 MB กรุณาเลือกรูปอื่น');
      return;
    }
    setState(() {
      _image = file;
      _preview = bytes;
    });
  }
}

class _PhotoPicker extends StatelessWidget {
  final Uint8List? preview;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PhotoPicker({
    required this.preview,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(preview == null ? 'แนบรูป' : 'เปลี่ยนรูป'),
        ),
        if (preview != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  preview!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              IconButton(
                tooltip: 'เอารูปออก',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
