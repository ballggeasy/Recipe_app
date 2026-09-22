/// รีวิวสูตรอาหาร
class Review {
  final String id;
  final String recipeId;
  final String userId;
  final String userName;
  final double rating;
  final String content;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<String> likedByUserIds;
  final List<ReviewReply> replies;
  final bool isReported;

  const Review({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.imageUrls = const [],
    this.likedByUserIds = const [],
    this.replies = const [],
    this.isReported = false,
  });

  int get likeCount => likedByUserIds.length;

  bool likedBy(String? userId) => userId != null && likedByUserIds.contains(userId);

  factory Review.fromApi(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        rating: (json['rating'] as num).toDouble(),
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? const [],
        likedByUserIds: (json['likedByUserIds'] as List?)?.cast<String>() ?? const [],
        replies: (json['replies'] as List? ?? [])
            .map((r) => ReviewReply.fromApi(r as Map<String, dynamic>))
            .toList(),
        isReported: json['isReported'] as bool? ?? false,
      );
}

class ReviewReply {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  const ReviewReply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory ReviewReply.fromApi(Map<String, dynamic> json) => ReviewReply(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
