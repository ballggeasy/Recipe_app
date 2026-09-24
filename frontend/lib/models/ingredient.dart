/// วัตถุดิบแบบมีโครงสร้าง — ชื่อ, ปริมาณ, หน่วย
class IngredientItem {
  final String name;
  final String amount;
  final String unit;

  const IngredientItem({
    required this.name,
    required this.amount,
    required this.unit,
  });

  String get display {
    if (amount.isEmpty && unit.isEmpty) return name;
    if (unit.isEmpty) return '$amount $name';
    return '$amount $unit $name';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
      };

  factory IngredientItem.fromJson(Map<String, dynamic> json) => IngredientItem(
        name: json['name'] as String,
        amount: json['amount'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
      );
}
