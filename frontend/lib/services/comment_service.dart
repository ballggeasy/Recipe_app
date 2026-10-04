import 'package:image_picker/image_picker.dart';

import '../models/comment.dart';
import 'api_client.dart';

/// เรียก backend API สำหรับคอมเมนต์ (nested) — อ่านสาธารณะ, เขียน/ลบต้อง auth
class CommentService {
  final ApiClient _api;

  CommentService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Comment>> fetchForRecipe(String recipeId) async {
    final data =
        await _api.get('/recipes/$recipeId/comments', auth: false) as List;
    return data.map((e) => Comment.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<Comment> create(
    String recipeId, {
    required String content,
    String? parentId,
    List<String> mentions = const [],
    String? imageUrl,
  }) async {
    final data =
        await _api.post(
              '/recipes/$recipeId/comments',
              body: {
                'content': content,
                'parentId': ?parentId,
                'mentions': mentions,
                'imageUrl': ?imageUrl,
              },
            )
            as Map<String, dynamic>;
    return Comment.fromApi(data);
  }

  Future<void> delete(String id) => _api.delete('/comments/$id');

  Future<Comment> uploadImage(String commentId, XFile file) async {
    final data =
        await _api.uploadFile(
              '/comments/$commentId/image',
              fieldName: 'file',
              bytes: await file.readAsBytes(),
              filename: file.name,
              contentType: file.mimeType,
            )
            as Map<String, dynamic>;
    return Comment.fromApi(data);
  }
}
