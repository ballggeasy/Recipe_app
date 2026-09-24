/// คอมเมนต์ใต้สูตรอาหาร (รองรับ reply แบบ nested)
class Comment {
  final String id;
  final String recipeId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String> mentions;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.mentions = const [],
    this.replies = const [],
  });

  factory Comment.fromApi(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        imageUrl: json['imageUrl'] as String?,
        mentions: (json['mentions'] as List?)?.cast<String>() ?? const [],
        replies: (json['replies'] as List? ?? [])
            .map((r) => Comment.fromApi(r as Map<String, dynamic>))
            .toList(),
      );
}
