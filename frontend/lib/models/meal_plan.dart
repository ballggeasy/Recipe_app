/// รายการมื้ออาหารในแผน
class MealPlanEntry {
  final String id;
  final String recipeId;
  final DateTime date;
  final MealType mealType;
  final int servings;

  const MealPlanEntry({
    required this.id,
    required this.recipeId,
    required this.date,
    required this.mealType,
    this.servings = 1,
  });

  MealPlanEntry copyWith({
    String? recipeId,
    DateTime? date,
    MealType? mealType,
    int? servings,
  }) {
    return MealPlanEntry(
      id: id,
      recipeId: recipeId ?? this.recipeId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      servings: servings ?? this.servings,
    );
  }

  factory MealPlanEntry.fromApi(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        // backend ส่งเวลาแบบ UTC ('...Z') — แปลงเป็นเวลาเครื่องก่อน ไม่งั้นมื้อช่วง 00:00-06:59 (UTC+7) จะไปอยู่วันก่อนหน้า
        date: DateTime.parse(json['date'] as String).toLocal(),
        mealType: MealType.values.byName(json['mealType'] as String),
        servings: json['servings'] as int? ?? 1,
      );
}

enum MealType {
  breakfast('อาหารเช้า', '🌅'),
  lunch('อาหารกลางวัน', '☀️'),
  dinner('อาหารเย็น', '🌙'),
  snack('ของว่าง', '🍪');

  final String label;
  final String emoji;
  const MealType(this.label, this.emoji);
}
