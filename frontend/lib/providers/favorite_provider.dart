import 'package:flutter/foundation.dart';

import '../models/favorite_folder.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';

/// จัดการโฟลเดอร์สูตรโปรดผ่าน backend — ต้องล็อกอิน (guest จะเห็นรายการว่าง)
class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService;

  FavoriteProvider({FavoriteService? favoriteService}) : _favoriteService = favoriteService ?? FavoriteService();

  List<FavoriteFolder> _folders = [];
  bool _isLoading = false;
  // เพิ่มทุกครั้งที่ onAuthChanged ถูกเรียก — ใช้ทิ้งผลของ request ที่ยิงตอนสถานะล็อกอินก่อนหน้า
  int _authGeneration = 0;

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

  /// เรียกทุกครั้งที่สถานะล็อกอินเปลี่ยน
  Future<void> onAuthChanged(bool isLoggedIn) async {
    final generation = ++_authGeneration;
    if (!isLoggedIn) {
      _folders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    List<FavoriteFolder> folders;
    try {
      folders = await _favoriteService.listFolders();
    } on ApiException {
      folders = [];
    }
    if (generation != _authGeneration) return; // logout/เปลี่ยนบัญชีระหว่างรอ — ผลนี้เป็นของคนก่อน
    _folders = folders;
    _isLoading = false;
    notifyListeners();
  }

  /// คืน error message ถ้าสร้างไม่สำเร็จ ไม่งั้นคืน null
  Future<String?> createFolder(String name, {String emoji = '📁'}) async {
    try {
      final folder = await _favoriteService.createFolder(name, emoji: emoji);
      _folders.add(folder);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _favoriteService.deleteFolder(id);
      _folders.removeWhere((f) => f.id == id);
      notifyListeners();
    } on ApiException {
      // ลบไม่สำเร็จ — คงรายการเดิมไว้
    }
  }

  Future<void> addRecipeToFolder(String folderId, String recipeId) async {
    try {
      final updated = await _favoriteService.addRecipeToFolder(folderId, recipeId);
      final index = _folders.indexWhere((f) => f.id == folderId);
      if (index != -1) {
        _folders[index] = updated;
        notifyListeners();
      }
    } on ApiException {
      // เพิ่มไม่สำเร็จ
    }
  }

  Future<void> removeRecipeFromFolder(String folderId, String recipeId) async {
    try {
      final updated = await _favoriteService.removeRecipeFromFolder(folderId, recipeId);
      final index = _folders.indexWhere((f) => f.id == folderId);
      if (index != -1) {
        _folders[index] = updated;
        notifyListeners();
      }
    } on ApiException {
      // ลบไม่สำเร็จ
    }
  }

  /// mock — แชร์สูตร (คืนลิงก์จำลอง)
  String shareRecipe(Recipe recipe) {
    return 'https://recipe-app.demo/share/${recipe.id}';
  }

  /// mock — ดาวน์โหลดสูตร (คืนชื่อไฟล์จำลอง)
  String downloadRecipe(Recipe recipe) {
    return '${recipe.name.replaceAll(' ', '_')}.pdf';
  }
}
