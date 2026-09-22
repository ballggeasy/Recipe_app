import 'ingredient.dart';
import 'nutrition.dart';

/// สูตรอาหาร — โมเดลหลักของแอป
class Recipe {
  final String id;
  final String name;
  final String emoji;
  final String imageUrl;
  final String category;
  final int cookTimeMinutes;
  final int prepTimeMinutes;
  final String difficulty;
  final List<String> ingredients;
  final List<IngredientItem> ingredientItems;
  final List<String> steps;
  final String country;
  final bool isOfficial;
  final String? uploaderId;
  final String? uploaderName;
  final double rating;
  final int reviewCount;
  final int servings;
  final String? tips;
  final String? platingTips;
  final NutritionInfo? nutrition;
  final List<String> dietTags;
  final String season;
  final DateTime createdAt;
  final int viewCount;
  final bool isRecommended;
  final List<String> imageUrls;
  final String? videoUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imageUrl,
    required this.category,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.country,
    this.prepTimeMinutes = 10,
    this.ingredientItems = const [],
    this.isOfficial = true,
    this.uploaderId,
    this.uploaderName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.servings = 2,
    this.tips,
    this.platingTips,
    this.nutrition,
    this.dietTags = const [],
    this.season = 'ตลอดปี',
    DateTime? createdAt,
    this.viewCount = 0,
    this.isRecommended = false,
    List<String>? imageUrls,
    this.videoUrl,
  })  : createdAt = createdAt ?? DateTime(2025, 6, 1),
        imageUrls = imageUrls ?? const [];

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  List<String> get allImages =>
      imageUrls.isNotEmpty ? imageUrls : (imageUrl.isNotEmpty ? [imageUrl] : []);

  String get sourceLabel =>
      isOfficial ? 'สูตรทางการ' : 'โดย ${uploaderName ?? 'ผู้ใช้'}';

  bool matchesIngredientQuery(String query) {
    if (query.trim().isEmpty) return true;
    final lowerQuery = query.toLowerCase().trim();
    if (ingredients.any((i) => i.toLowerCase().contains(lowerQuery))) return true;
    return ingredientItems.any((i) => i.name.toLowerCase().contains(lowerQuery));
  }

  bool matchesNameQuery(String query) {
    if (query.trim().isEmpty) return true;
    return name.toLowerCase().contains(query.toLowerCase().trim());
  }

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    return matchesNameQuery(query) || matchesIngredientQuery(query);
  }

  bool matchesDietTag(String tag) => dietTags.contains(tag);

  Recipe copyWith({
    String? name,
    String? emoji,
    String? imageUrl,
    String? category,
    int? cookTimeMinutes,
    int? prepTimeMinutes,
    String? difficulty,
    List<String>? ingredients,
    List<IngredientItem>? ingredientItems,
    List<String>? steps,
    String? country,
    bool? isOfficial,
    String? uploaderName,
    double? rating,
    int? reviewCount,
    int? servings,
    String? tips,
    String? platingTips,
    NutritionInfo? nutrition,
    List<String>? dietTags,
    String? season,
    DateTime? createdAt,
    int? viewCount,
    bool? isRecommended,
    List<String>? imageUrls,
    String? videoUrl,
  }) {
    return Recipe(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      ingredients: ingredients ?? this.ingredients,
      ingredientItems: ingredientItems ?? this.ingredientItems,
      steps: steps ?? this.steps,
      country: country ?? this.country,
      isOfficial: isOfficial ?? this.isOfficial,
      uploaderName: uploaderName ?? this.uploaderName,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      servings: servings ?? this.servings,
      tips: tips ?? this.tips,
      platingTips: platingTips ?? this.platingTips,
      nutrition: nutrition ?? this.nutrition,
      dietTags: dietTags ?? this.dietTags,
      season: season ?? this.season,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      isRecommended: isRecommended ?? this.isRecommended,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  factory Recipe.fromApi(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? const [],
        category: json['category'] as String,
        country: json['country'] as String,
        cookTimeMinutes: json['cookTimeMinutes'] as int,
        prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 10,
        difficulty: json['difficulty'] as String,
        servings: json['servings'] as int? ?? 2,
        ingredients: (json['ingredients'] as List?)?.cast<String>() ?? const [],
        ingredientItems: (json['ingredientItems'] as List? ?? [])
            .map((e) => IngredientItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List?)?.cast<String>() ?? const [],
        isOfficial: json['isOfficial'] as bool? ?? true,
        uploaderId: json['uploaderId'] as String?,
        uploaderName: json['uploaderName'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        tips: json['tips'] as String?,
        platingTips: json['platingTips'] as String?,
        nutrition: json['nutrition'] != null
            ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
            : null,
        dietTags: (json['dietTags'] as List?)?.cast<String>() ?? const [],
        season: json['season'] as String? ?? 'ตลอดปี',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        viewCount: json['viewCount'] as int? ?? 0,
        isRecommended: json['isRecommended'] as bool? ?? false,
        videoUrl: json['videoUrl'] as String?,
      );
}
