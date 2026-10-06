import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/review.dart';
import '../services/api_client.dart';
import '../services/review_service.dart';

/// จัดการรีวิวผ่าน backend: ให้คะแนน, รีวิว, ถูกใจ, รายงาน, ตอบกลับ
class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService;

  ReviewProvider({ReviewService? reviewService})
    : _reviewService = reviewService ?? ReviewService();

  final Map<String, List<Review>> _reviewsByRecipe = {};
  final Set<String> _loadingRecipeIds = {};
  int _authEpoch = 0;

  /// ล้างแคชตอนสลับบัญชี เพื่อไม่ให้สถานะถูกใจ/รีวิวของคนก่อนค้างบนหน้า
  void onAuthChanged() {
    _authEpoch++;
    _reviewsByRecipe.clear();
    _loadingRecipeIds.clear();
    notifyListeners();
  }

  List<Review> getReviewsForRecipe(String recipeId) =>
      _reviewsByRecipe[recipeId] ?? const [];

  bool isLoading(String recipeId) => _loadingRecipeIds.contains(recipeId);

  double getAverageRating(String recipeId) {
    final list = getReviewsForRecipe(recipeId);
    if (list.isEmpty) return 0;
    return list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;
  }

  Future<void> loadForRecipe(String recipeId) async {
    final epoch = _authEpoch;
    _loadingRecipeIds.add(recipeId);
    notifyListeners();
    try {
      final reviews = await _reviewService.fetchForRecipe(recipeId);
      if (epoch != _authEpoch) return;
      _reviewsByRecipe[recipeId] = reviews;
    } on ApiException {
      if (epoch != _authEpoch) return;
      _reviewsByRecipe[recipeId] = _reviewsByRecipe[recipeId] ?? [];
    }
    if (epoch != _authEpoch) return;
    _loadingRecipeIds.remove(recipeId);
    notifyListeners();
  }

  /// `error` = ส่งรีวิวไม่สำเร็จ, `imageError` = รีวิวถูกบันทึกแล้วแต่รูปไม่ขึ้น
  Future<({String? error, String? imageError})> addReview({
    required String recipeId,
    required double rating,
    required String content,
    List<String> imageUrls = const [],
    XFile? image,
  }) async {
    final epoch = _authEpoch;
    try {
      var review = await _reviewService.create(
        recipeId,
        rating: rating,
        content: content,
        imageUrls: imageUrls,
      );
      String? imageError;
      if (image != null && epoch == _authEpoch) {
        try {
          review = await _reviewService.uploadImage(review.id, image);
        } on ApiException catch (e) {
          imageError = e.message;
        }
      }
      if (epoch != _authEpoch) return (error: null, imageError: imageError);
      final list = _reviewsByRecipe.putIfAbsent(recipeId, () => []);
      // ผู้ใช้มีรีวิวได้หนึ่งรีวิวต่อสูตร: รีวิวซ้ำ backend จะแก้รีวิวเดิม (id เดิม) ไม่ใช่เพิ่มใหม่
      list.removeWhere((r) => r.id == review.id);
      list.insert(0, review);
      notifyListeners();
      return (error: null, imageError: imageError);
    } on ApiException catch (e) {
      return (error: e.message, imageError: null);
    }
  }

  /// คืนข้อความ error ถ้าลบไม่สำเร็จ — คนอื่นลบรีวิวของเราไม่ได้
  Future<String?> deleteReview(String reviewId) async {
    final epoch = _authEpoch;
    try {
      await _reviewService.delete(reviewId);
      if (epoch != _authEpoch) return null;
      for (final list in _reviewsByRecipe.values) {
        final index = list.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          list.removeAt(index);
          notifyListeners();
          break;
        }
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> toggleLike(String reviewId) async {
    final epoch = _authEpoch;
    try {
      final updated = await _reviewService.toggleLike(reviewId);
      if (epoch != _authEpoch) return;
      _replaceReview(updated);
    } on ApiException {
      // ไม่สำเร็จ — คงเดิม
    }
  }

  Future<void> reportReview(String reviewId) async {
    final epoch = _authEpoch;
    try {
      final updated = await _reviewService.report(reviewId);
      if (epoch != _authEpoch) return;
      _replaceReview(updated);
    } on ApiException {
      // ไม่สำเร็จ
    }
  }

  Future<void> addReply(String reviewId, String content) async {
    final epoch = _authEpoch;
    try {
      final updated = await _reviewService.addReply(reviewId, content);
      if (epoch != _authEpoch) return;
      _replaceReview(updated);
    } on ApiException {
      // ไม่สำเร็จ
    }
  }

  void _replaceReview(Review updated) {
    final list = _reviewsByRecipe[updated.recipeId];
    if (list == null) return;
    final index = list.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      notifyListeners();
    }
  }
}
