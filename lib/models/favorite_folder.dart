/// โฟลเดอร์เก็บสูตรโปรด
class FavoriteFolder {
  final String id;
  final String name;
  final String emoji;
  final List<String> recipeIds;
  final DateTime createdAt;

  const FavoriteFolder({
    required this.id,
    required this.name,
    this.emoji = '📁',
    this.recipeIds = const [],
    required this.createdAt,
  });

  FavoriteFolder copyWith({
    String? name,
    String? emoji,
    List<String>? recipeIds,
  }) {
    return FavoriteFolder(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      recipeIds: recipeIds ?? this.recipeIds,
      createdAt: createdAt,
    );
  }

  factory FavoriteFolder.fromApi(Map<String, dynamic> json) => FavoriteFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📁',
        recipeIds: (json['recipeIds'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
