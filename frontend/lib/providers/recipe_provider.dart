import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';
import '../models/nutrition.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../services/recipe_service.dart';
import '../utils/constants.dart';

/// จัดการ state หลัก: รายการสูตร (จาก backend), ค้นหา, กรอง, เรียง, favorites
class RecipeProvider extends ChangeNotifier {
  final RecipeService _recipeService;
  final FavoriteService _favoriteService;

  RecipeProvider({
    RecipeService? recipeService,
    FavoriteService? favoriteService,
  }) : _recipeService = recipeService ?? RecipeService(),
       _favoriteService = favoriteService ?? FavoriteService();

  List<Recipe> _allRecipes = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  bool _canSyncFavorites = false;
  String? _loadError;

  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  String _selectedCountry = 'ทั้งหมด';
  SourceFilter _selectedSource = SourceFilter.all;
  SortOption _sortOption = SortOption.ratingDesc;
  RecipeListMode _listMode = RecipeListMode.all;
  // seed ของโหมดสุ่ม — สุ่มใหม่เฉพาะตอนผู้ใช้เลือกโหมดสุ่ม ไม่ใช่ทุกครั้งที่ filteredRecipes ถูกเรียก (ทุก rebuild)
  int _randomSeed = 0;
  String? _selectedDietTag;
  int? _maxCookTime;
  String? _selectedDifficulty;
  List<String> _searchHistory = [];
  String _historyScope = 'search_history';
  int _authEpoch = 0;

  List<Recipe> get allRecipes => _allRecipes;
  bool get isLoading => _isLoading;

  /// ข้อความ error ของการโหลดสูตรครั้งล่าสุด — null ถ้าโหลดสำเร็จ
  String? get loadError => _loadError;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedCountry => _selectedCountry;
  SourceFilter get selectedSource => _selectedSource;
  SortOption get sortOption => _sortOption;
  RecipeListMode get listMode => _listMode;
  String? get selectedDietTag => _selectedDietTag;
  int? get maxCookTime => _maxCookTime;
  String? get selectedDifficulty => _selectedDifficulty;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  List<String> get categories {
    final cats = _allRecipes.map((r) => r.category).toSet().toList()..sort();
    return ['ทั้งหมด', ...cats];
  }

  List<String> get countries {
    final list = _allRecipes.map((r) => r.country).toSet().toList()..sort();
    return ['ทั้งหมด', ...list];
  }

  Recipe? getById(String id) {
    try {
      return _allRecipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Recipe> get filteredRecipes {
    var list = _allRecipes.where((recipe) {
      final matchesCategory =
          _selectedCategory == 'ทั้งหมด' ||
          recipe.category == _selectedCategory;
      final matchesCountry =
          _selectedCountry == 'ทั้งหมด' || recipe.country == _selectedCountry;
      final matchesSource = switch (_selectedSource) {
        SourceFilter.all => true,
        SourceFilter.official => recipe.isOfficial,
        SourceFilter.user => !recipe.isOfficial,
      };
      final matchesSearch = recipe.matchesQuery(_searchQuery);
      final matchesDiet =
          _selectedDietTag == null || recipe.matchesDietTag(_selectedDietTag!);
      final matchesTime =
          _maxCookTime == null || recipe.totalTimeMinutes <= _maxCookTime!;
      final matchesDiff =
          _selectedDifficulty == null ||
          recipe.difficulty == _selectedDifficulty;
      return matchesCategory &&
          matchesCountry &&
          matchesSource &&
          matchesSearch &&
          matchesDiet &&
          matchesTime &&
          matchesDiff;
    }).toList();

    list = _applyListMode(list);
    return _sort(list);
  }

  List<Recipe> _applyListMode(List<Recipe> list) {
    switch (_listMode) {
      case RecipeListMode.all:
        return list;
      case RecipeListMode.latest:
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted.take(10).toList();
      case RecipeListMode.popular:
        final sorted = [...list]
          ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
        return sorted.take(10).toList();
      case RecipeListMode.recommended:
        return list.where((r) => r.isRecommended).toList();
      case RecipeListMode.random:
        final shuffled = [...list]..shuffle(Random(_randomSeed));
        return shuffled.take(6).toList();
      case RecipeListMode.seasonal:
        return list.where((r) => r.season != 'ตลอดปี').toList();
      case RecipeListMode.diet:
        return _selectedDietTag != null
            ? list.where((r) => r.matchesDietTag(_selectedDietTag!)).toList()
            : list;
    }
  }

  List<Recipe> _sort(List<Recipe> list) {
    final sorted = [...list];
    switch (_sortOption) {
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
      case SortOption.ratingDesc:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.timeAsc:
        sorted.sort((a, b) => a.totalTimeMinutes.compareTo(b.totalTimeMinutes));
      case SortOption.timeDesc:
        sorted.sort((a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
      case SortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.popular:
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    }
    return sorted;
  }

  List<Recipe> get favoriteRecipes =>
      _allRecipes.where((r) => _favoriteIds.contains(r.id)).toList();

  bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);

  /// Auto-complete suggestions จากชื่อเมนูและวัตถุดิบ
  List<String> getAutocompleteSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final names = _allRecipes
        .where((r) => r.name.toLowerCase().contains(q))
        .map((r) => r.name);
    final ingredients = _allRecipes
        .expand((r) => r.ingredients)
        .where((i) => i.toLowerCase().contains(q))
        .map(
          (i) => i.split(' ').skip(1).join(' ').isEmpty
              ? i
              : i.split(' ').skip(1).join(' '),
        );
    return {...names, ...ingredients}.take(8).toList();
  }

  /// เรียกตอนเปิดแอป — โหลดรายการสูตรจาก backend
  /// ประวัติค้นหาโหลดทีหลังใน [onAuthChanged] เพื่อไม่ให้ทุกบัญชีใช้รายการเดียวกัน
  Future<void> init() async {
    await loadRecipes();
  }

  /// โหลดรายการสูตรจาก backend — ถ้าล้มเหลวจะเก็บข้อความไว้ใน [loadError] (และคงรายการเดิมไว้)
  /// ให้หน้าจอแสดงปุ่ม "ลองอีกครั้ง" ที่เรียกเมธอดนี้ซ้ำได้
  Future<void> loadRecipes() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _allRecipes = await _recipeService.fetchAll();
    } on ApiException catch (e) {
      _loadError = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// โหลดรายการสูตรใหม่โดยไม่ขึ้นสถานะกำลังโหลด — ใช้ดึงค่าโภชนาการที่ backend ประเมินเสร็จทีหลัง
  /// (backend ให้ AI ประเมินเองหลังเพิ่มสูตรหรือเปลี่ยนรูป ราว 10 วินาที) ถ้าโหลดไม่ได้ก็คงรายการเดิม
  Future<void> refreshQuietly() async {
    try {
      _allRecipes = await _recipeService.fetchAll();
      notifyListeners();
    } on ApiException {
      // คงรายการเดิม
    }
  }

  /// ให้ AI ประเมินโภชนาการของสูตรนี้ใหม่ทันที (เฉพาะสูตรของตัวเอง) — คืน error message ถ้าไม่สำเร็จ
  Future<String?> estimateNutrition(String id) async {
    try {
      final updated = await _recipeService.estimateNutrition(id);
      final index = _allRecipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _allRecipes[index] = updated;
        notifyListeners();
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// เรียกทุกครั้งที่สถานะล็อกอินเปลี่ยน — favorites และประวัติค้นหาเป็นของบัญชีนั้นเท่านั้น
  /// ล้างรายการเก่าทันที แล้วค่อยโหลดของบัญชีใหม่ (โหลดไม่สำเร็จ = ว่าง ไม่ยืมของบัญชีก่อน)
  /// คำตอบที่กลับมาช้าจากบัญชีก่อนหน้าจะถูกทิ้ง
  Future<void> onAuthChanged(bool isLoggedIn, {String? userId}) async {
    final epoch = ++_authEpoch;
    _canSyncFavorites = isLoggedIn;
    _favoriteIds = {};
    notifyListeners();

    final scope = _historyScopeFor(isLoggedIn, userId);
    if (scope != _historyScope) {
      _historyScope = scope;
      final prefs = await SharedPreferences.getInstance();
      if (epoch != _authEpoch) return;
      _searchHistory = prefs.getStringList(_historyScope) ?? [];
      notifyListeners();
    }

    if (!isLoggedIn) return;

    try {
      final ids = await _favoriteService.listFavoriteIds();
      if (epoch != _authEpoch) return;
      _favoriteIds = ids.toSet();
    } on ApiException {
      if (epoch != _authEpoch) return;
      _favoriteIds = {};
    }
    if (epoch != _authEpoch) return;
    notifyListeners();
  }

  String _historyScopeFor(bool isLoggedIn, String? userId) {
    if (!isLoggedIn) return 'search_history_guest';
    if (userId == null) return _historyScope;
    return 'search_history_$userId';
  }

  Future<void> _persistSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyScope, _searchHistory);
  }

  void toggleFavorite(String recipeId) {
    final wasFavorite = _favoriteIds.contains(recipeId);
    if (wasFavorite) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    notifyListeners();

    if (!_canSyncFavorites) return;
    final epoch = _authEpoch;
    final future = wasFavorite
        ? _favoriteService.removeFavorite(recipeId)
        : _favoriteService.addFavorite(recipeId);
    future.catchError((_) {
      if (epoch != _authEpoch) return;
      if (wasFavorite) {
        _favoriteIds.add(recipeId);
      } else {
        _favoriteIds.remove(recipeId);
      }
      notifyListeners();
    });
  }

  void addToSearchHistory(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > AppConstants.maxSearchHistory) {
      _searchHistory = _searchHistory
          .take(AppConstants.maxSearchHistory)
          .toList();
    }
    notifyListeners();
    _persistSearchHistory();
  }

  void clearSearchHistory() {
    _searchHistory = [];
    notifyListeners();
    _persistSearchHistory();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSelectedCountry(String country) {
    _selectedCountry = country;
    notifyListeners();
  }

  void updateSelectedSource(SourceFilter source) {
    _selectedSource = source;
    notifyListeners();
  }

  void updateSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void updateListMode(RecipeListMode mode, {String? dietTag}) {
    if (mode == RecipeListMode.random) _randomSeed = Random().nextInt(1 << 31);
    _listMode = mode;
    _selectedDietTag = dietTag;
    notifyListeners();
  }

  void updateMaxCookTime(int? minutes) {
    _maxCookTime = minutes;
    notifyListeners();
  }

  void updateSelectedDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'ทั้งหมด';
    _selectedCountry = 'ทั้งหมด';
    _selectedSource = SourceFilter.all;
    _selectedDietTag = null;
    _maxCookTime = null;
    _selectedDifficulty = null;
    _listMode = RecipeListMode.all;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// เพิ่มสูตรใหม่ผ่าน backend แล้วอัปโหลด [image] ให้สูตรนั้น (ถ้ามี)
  ///
  /// - `error` ไม่เป็น null: สร้างสูตรไม่สำเร็จ ไม่มีอะไรถูกบันทึก
  /// - `imageError` ไม่เป็น null: สูตรถูกบันทึกแล้วแต่อัปโหลดรูปไม่สำเร็จ — ห้ามให้ผู้ใช้กดบันทึกซ้ำ
  ///   (จะได้สูตรซ้ำ) ให้ไปเพิ่มรูปทีหลังที่หน้าแก้ไขแทน
  Future<({String? error, String? imageError})> addRecipe({
    required String name,
    required String emoji,
    required String category,
    required String country,
    required int prepTime,
    required int cookTime,
    required String difficulty,
    required int servings,
    required List<String> steps,
    required List<String> ingredients,
    String? tips,
    String? platingTips,
    List<String> dietTags = const [],
    NutritionInfo? nutrition,
    String? videoUrl,
    XFile? image,
  }) async {
    final Recipe recipe;
    try {
      recipe = await _recipeService.create(
        name: name,
        emoji: emoji,
        category: category,
        country: country,
        cookTimeMinutes: cookTime,
        prepTimeMinutes: prepTime,
        difficulty: difficulty,
        servings: servings,
        ingredients: ingredients,
        steps: steps,
        tips: tips,
        platingTips: platingTips,
        dietTags: dietTags,
        nutrition: nutrition,
        videoUrl: videoUrl,
      );
    } on ApiException catch (e) {
      return (error: e.message, imageError: null);
    }

    _allRecipes.insert(0, recipe);
    notifyListeners();

    if (image == null) return (error: null, imageError: null);
    return (error: null, imageError: await updateRecipeImage(recipe.id, image));
  }

  /// อัปโหลดรูปเมนูใหม่แทนรูปเดิม (เฉพาะสูตรที่ตัวเองอัปโหลด) — คืน error message ถ้าไม่สำเร็จ
  Future<String?> updateRecipeImage(String id, XFile image) async {
    try {
      final updated = await _recipeService.uploadImage(id, image);
      final index = _allRecipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _allRecipes[index] = updated;
        notifyListeners();
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// แก้ไขสูตร (เฉพาะสูตรที่ตัวเองอัปโหลด — backend ตรวจสอบสิทธิ์)
  Future<String?> updateRecipe(Recipe recipe) async {
    try {
      final updated = await _recipeService.update(recipe.id, {
        'name': recipe.name,
        'emoji': recipe.emoji,
        'category': recipe.category,
        'country': recipe.country,
        'cookTimeMinutes': recipe.cookTimeMinutes,
        'prepTimeMinutes': recipe.prepTimeMinutes,
        'difficulty': recipe.difficulty,
        'servings': recipe.servings,
        'ingredients': recipe.ingredients,
        'ingredientItems': recipe.ingredientItems
            .map((i) => i.toJson())
            .toList(),
        'steps': recipe.steps,
        'tips': recipe.tips,
        'platingTips': recipe.platingTips,
        'dietTags': recipe.dietTags,
        if (recipe.nutrition != null) 'nutrition': recipe.nutrition!.toJson(),
        'videoUrl': recipe.videoUrl,
      });
      final index = _allRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _allRecipes[index] = updated;
        notifyListeners();
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// ลบสูตร (เฉพาะสูตรที่ตัวเองอัปโหลด — backend ตรวจสอบสิทธิ์)
  Future<String?> deleteRecipe(String id) async {
    try {
      await _recipeService.delete(id);
      _allRecipes.removeWhere((r) => r.id == id);
      _favoriteIds.remove(id);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
