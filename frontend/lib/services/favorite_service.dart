import '../models/favorite_folder.dart';
import 'api_client.dart';

/// เรียก backend API สำหรับสูตรโปรด (quick favorite) และโฟลเดอร์ — auth เสมอ
class FavoriteService {
  final ApiClient _api;

  FavoriteService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<String>> listFavoriteIds() async {
    final data = await _api.get('/favorites') as List;
    return data.cast<String>();
  }

  Future<void> addFavorite(String recipeId) => _api.post('/favorites/$recipeId');

  Future<void> removeFavorite(String recipeId) => _api.delete('/favorites/$recipeId');

  Future<List<FavoriteFolder>> listFolders() async {
    final data = await _api.get('/folders') as List;
    return data.map((e) => FavoriteFolder.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<FavoriteFolder> createFolder(String name, {String emoji = '📁'}) async {
    final data = await _api.post('/folders', body: {'name': name, 'emoji': emoji}) as Map<String, dynamic>;
    return FavoriteFolder.fromApi(data);
  }

  Future<void> deleteFolder(String id) => _api.delete('/folders/$id');

  Future<FavoriteFolder> addRecipeToFolder(String folderId, String recipeId) async {
    final data = await _api.post('/folders/$folderId/recipes/$recipeId') as Map<String, dynamic>;
    return FavoriteFolder.fromApi(data);
  }

  Future<FavoriteFolder> removeRecipeFromFolder(String folderId, String recipeId) async {
    final data = await _api.delete('/folders/$folderId/recipes/$recipeId') as Map<String, dynamic>;
    return FavoriteFolder.fromApi(data);
  }
}
