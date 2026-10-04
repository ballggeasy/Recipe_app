import '../models/recipe.dart';

/// ข้อความสูตรที่ใช้แชร์และบันทึกเป็นไฟล์
String recipeDocument(Recipe recipe) {
  final lines = <String>[
    recipe.name,
    '${recipe.category} · ${recipe.country}',
    'เตรียม ${recipe.prepTimeMinutes} นาที · ปรุง ${recipe.cookTimeMinutes} นาที · ${recipe.servings} ที่',
    '',
    'ส่วนผสม',
    ...recipe.ingredients.map((item) => '- $item'),
    '',
    'ขั้นตอน',
    for (var i = 0; i < recipe.steps.length; i++)
      '${i + 1}. ${recipe.steps[i]}',
  ];
  if (recipe.tips != null && recipe.tips!.trim().isNotEmpty) {
    lines.addAll(['', 'เคล็ดลับ', recipe.tips!.trim()]);
  }
  return lines.join('\n');
}

/// ลิงก์วิดีโอจริงถ้ามี ไม่เช่นนั้นเปิดผลการค้นหาวิธีทำของเมนูนี้
Uri recipeVideoUri(Recipe recipe) {
  final url = recipe.videoUrl?.trim();
  if (url != null &&
      (url.startsWith('https://') || url.startsWith('http://'))) {
    return Uri.parse(url);
  }
  return Uri.https('www.youtube.com', '/results', {
    'search_query': '${recipe.name} สูตร',
  });
}

bool hasRecipeVideo(Recipe recipe) {
  final url = recipe.videoUrl?.trim();
  return url != null && url.isNotEmpty;
}
