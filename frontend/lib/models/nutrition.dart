/// ข้อมูลโภชนาการต่อ 1 เสิร์ฟ
class NutritionInfo {
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double sugar;
  final double sodium;

  const NutritionInfo({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  /// คำนวณโภชนาการตามจำนวนเสิร์ฟ
  NutritionInfo forServings(int servings) {
    if (servings <= 1) return this;
    return NutritionInfo(
      calories: (calories * servings).round(),
      protein: protein * servings,
      fat: fat * servings,
      carbs: carbs * servings,
      sugar: sugar * servings,
      sodium: sodium * servings,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'sugar': sugar,
        'sodium': sodium,
      };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: json['calories'] as int? ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
        sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
      );
}
