import 'package:flutter/foundation.dart';

import '../models/comment.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';

/// จัดการคอมเมนต์ผ่าน backend: แสดง, ตอบกลับ, mention, ลบ (nested tree มาจาก backend แล้ว)
class CommentProvider extends ChangeNotifier {
  final CommentService _commentService;

  CommentProvider({CommentService? commentService}) : _commentService = commentService ?? CommentService();

  final Map<String, List<Comment>> _commentsByRecipe = {};
  final Set<String> _loadingRecipeIds = {};

  List<Comment> getTopLevelComments(String recipeId) =>
      _commentsByRecipe[recipeId] ?? const [];

  bool isLoading(String recipeId) => _loadingRecipeIds.contains(recipeId);

  Future<void> loadForRecipe(String recipeId) async {
    _loadingRecipeIds.add(recipeId);
    notifyListeners();
    try {
      _commentsByRecipe[recipeId] = await _commentService.fetchForRecipe(recipeId);
    } on ApiException {
      _commentsByRecipe[recipeId] = _commentsByRecipe[recipeId] ?? [];
    }
    _loadingRecipeIds.remove(recipeId);
    notifyListeners();
  }

  /// คืน error message ถ้าส่งไม่สำเร็จ (เช่น ยังไม่ได้ล็อกอิน) ไม่งั้นคืน null
  Future<String?> addComment({
    required String recipeId,
    required String content,
    String? parentId,
    List<String> mentions = const [],
    String? imageUrl,
  }) async {
    try {
      await _commentService.create(
        recipeId,
        content: content,
        parentId: parentId,
        mentions: mentions,
        imageUrl: imageUrl,
      );
      await loadForRecipe(recipeId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteComment(String recipeId, String commentId) async {
    try {
      await _commentService.delete(commentId);
      await loadForRecipe(recipeId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
