import 'package:flutter/foundation.dart';

import '../models/review.dart';
import '../services/api_client.dart';
import '../services/review_service.dart';

/// จัดการรีวิวผ่าน backend: ให้คะแนน, รีวิว, ถูกใจ, รายงาน, ตอบกลับ
class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  final Map<String, List<Review>> _reviewsByRecipe = {};
  final Set<String> _loadingRecipeIds = {};

  List<Review> getReviewsForRecipe(String recipeId) =>
      _reviewsByRecipe[recipeId] ?? const [];

  bool isLoading(String recipeId) => _loadingRecipeIds.contains(recipeId);

  double getAverageRating(String recipeId) {
    final list = getReviewsForRecipe(recipeId);
    if (list.isEmpty) return 0;
    return list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;
  }

  Future<void> loadForRecipe(String recipeId) async {
    _loadingRecipeIds.add(recipeId);
    notifyListeners();
    try {
      _reviewsByRecipe[recipeId] = await _reviewService.fetchForRecipe(recipeId);
    } on ApiException {
      _reviewsByRecipe[recipeId] = _reviewsByRecipe[recipeId] ?? [];
    }
    _loadingRecipeIds.remove(recipeId);
    notifyListeners();
  }

  Future<void> addReview({
    required String recipeId,
    required double rating,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    try {
      final review = await _reviewService.create(
        recipeId,
        rating: rating,
        content: content,
        imageUrls: imageUrls,
      );
      final list = _reviewsByRecipe.putIfAbsent(recipeId, () => []);
      list.insert(0, review);
      notifyListeners();
    } on ApiException {
      // ส่งรีวิวไม่สำเร็จ
    }
  }

  Future<void> toggleLike(String reviewId) async {
    try {
      final updated = await _reviewService.toggleLike(reviewId);
      _replaceReview(updated);
    } on ApiException {
      // ไม่สำเร็จ — คงเดิม
    }
  }

  Future<void> reportReview(String reviewId) async {
    try {
      final updated = await _reviewService.report(reviewId);
      _replaceReview(updated);
    } on ApiException {
      // ไม่สำเร็จ
    }
  }

  Future<void> addReply(String reviewId, String content) async {
    try {
      final updated = await _reviewService.addReply(reviewId, content);
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
