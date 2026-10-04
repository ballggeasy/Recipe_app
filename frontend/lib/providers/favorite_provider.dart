import 'package:flutter/foundation.dart';

import '../models/favorite_folder.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';

/// จัดการโฟลเดอร์สูตรโปรดผ่าน backend — ต้องล็อกอิน (guest จะเห็นรายการว่าง)
class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService;

  FavoriteProvider({FavoriteService? favoriteService})
    : _favoriteService = favoriteService ?? FavoriteService();

  List<FavoriteFolder> _folders = [];
  bool _isLoading = false;
  int _authEpoch = 0;

  List<FavoriteFolder> get folders => List.unmodifiable(_folders);
  bool get isLoading => _isLoading;

  FavoriteFolder? getFolder(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Recipe> recipesInFolder(String folderId, RecipeProvider recipeProvider) {
    final folder = getFolder(folderId);
    if (folder == null) return [];
    return folder.recipeIds
        .map((id) => recipeProvider.getById(id))
        .whereType<Recipe>()
        .toList();
  }

  /// เรียกทุกครั้งที่สถานะล็อกอินเปลี่ยน — โฟลเดอร์เป็นของบัญชีนั้นเท่านั้น
  /// คำตอบที่กลับมาช้าจากบัญชีก่อนหน้าจะถูกทิ้ง
  Future<void> onAuthChanged(bool isLoggedIn) async {
    final epoch = ++_authEpoch;
    _folders = [];
    if (!isLoggedIn) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final folders = await _favoriteService.listFolders();
      if (epoch != _authEpoch) return;
      _folders = folders;
    } on ApiException {
      if (epoch != _authEpoch) return;
      _folders = [];
    }
    if (epoch != _authEpoch) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createFolder(String name, {String emoji = '📁'}) async {
    final epoch = _authEpoch;
    try {
      final folder = await _favoriteService.createFolder(name, emoji: emoji);
      if (epoch != _authEpoch) return;
      _folders.add(folder);
      notifyListeners();
    } on ApiException {
      // ไม่สามารถสร้างโฟลเดอร์ได้ — เงียบไว้ ผู้ใช้ลองใหม่ได้
    }
  }

  Future<void> deleteFolder(String id) async {
    final epoch = _authEpoch;
    try {
      await _favoriteService.deleteFolder(id);
      if (epoch != _authEpoch) return;
      _folders.removeWhere((f) => f.id == id);
      notifyListeners();
    } on ApiException {
      // ลบไม่สำเร็จ — คงรายการเดิมไว้
    }
  }

  /// คืน true เมื่อบันทึกสำเร็จในบัญชีที่ยังล็อกอินอยู่
  Future<bool> addRecipeToFolder(String folderId, String recipeId) async {
    final epoch = _authEpoch;
    try {
      final updated = await _favoriteService.addRecipeToFolder(
        folderId,
        recipeId,
      );
      if (epoch != _authEpoch) return false;
      final index = _folders.indexWhere((f) => f.id == folderId);
      if (index != -1) {
        _folders[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException {
      return false;
    }
  }

  /// คืน true เมื่อเอาออกสำเร็จในบัญชีที่ยังล็อกอินอยู่
  Future<bool> removeRecipeFromFolder(String folderId, String recipeId) async {
    final epoch = _authEpoch;
    try {
      final updated = await _favoriteService.removeRecipeFromFolder(
        folderId,
        recipeId,
      );
      if (epoch != _authEpoch) return false;
      final index = _folders.indexWhere((f) => f.id == folderId);
      if (index != -1) {
        _folders[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException {
      return false;
    }
  }
}
