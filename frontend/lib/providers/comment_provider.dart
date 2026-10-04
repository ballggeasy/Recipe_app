import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/comment.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';

/// จัดการคอมเมนต์ผ่าน backend: แสดง, ตอบกลับ, mention, ลบ (nested tree มาจาก backend แล้ว)
class CommentProvider extends ChangeNotifier {
  final CommentService _commentService;

  CommentProvider({CommentService? commentService})
    : _commentService = commentService ?? CommentService();

  final Map<String, List<Comment>> _commentsByRecipe = {};
  final Set<String> _loadingRecipeIds = {};
  int _authEpoch = 0;

  /// ล้างแคชตอนสลับบัญชี
  void onAuthChanged() {
    _authEpoch++;
    _commentsByRecipe.clear();
    _loadingRecipeIds.clear();
    notifyListeners();
  }

  List<Comment> getTopLevelComments(String recipeId) =>
      _commentsByRecipe[recipeId] ?? const [];

  bool isLoading(String recipeId) => _loadingRecipeIds.contains(recipeId);

  Future<void> loadForRecipe(String recipeId) async {
    final epoch = _authEpoch;
    _loadingRecipeIds.add(recipeId);
    notifyListeners();
    try {
      final comments = await _commentService.fetchForRecipe(recipeId);
      if (epoch != _authEpoch) return;
      _commentsByRecipe[recipeId] = comments;
    } on ApiException {
      if (epoch != _authEpoch) return;
      _commentsByRecipe[recipeId] = _commentsByRecipe[recipeId] ?? [];
    }
    if (epoch != _authEpoch) return;
    _loadingRecipeIds.remove(recipeId);
    notifyListeners();
  }

  /// `error` = ส่งคอมเมนต์ไม่สำเร็จ, `imageError` = คอมเมนต์ถูกบันทึกแล้วแต่รูปไม่ขึ้น
  Future<({String? error, String? imageError})> addComment({
    required String recipeId,
    required String content,
    String? parentId,
    List<String> mentions = const [],
    String? imageUrl,
    XFile? image,
  }) async {
    final epoch = _authEpoch;
    try {
      final comment = await _commentService.create(
        recipeId,
        content: content,
        parentId: parentId,
        mentions: mentions,
        imageUrl: imageUrl,
      );
      String? imageError;
      if (image != null && epoch == _authEpoch) {
        try {
          await _commentService.uploadImage(comment.id, image);
        } on ApiException catch (e) {
          imageError = e.message;
        }
      }
      if (epoch != _authEpoch) return (error: null, imageError: imageError);
      await loadForRecipe(recipeId);
      return (error: null, imageError: imageError);
    } on ApiException catch (e) {
      return (error: e.message, imageError: null);
    }
  }

  /// คืนข้อความ error ถ้าลบไม่สำเร็จ — คนอื่นลบคอมเมนต์ของเราไม่ได้
  Future<String?> deleteComment(String recipeId, String commentId) async {
    final epoch = _authEpoch;
    try {
      await _commentService.delete(commentId);
      if (epoch != _authEpoch) return null;
      await loadForRecipe(recipeId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
