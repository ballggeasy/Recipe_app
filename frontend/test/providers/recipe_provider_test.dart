import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recipe_app/models/ingredient.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

final _catalog = [
  recipeJson(id: 'krapao', name: 'ผัดกะเพรา', rating: 4.5, cookTimeMinutes: 10, prepTimeMinutes: 5),
  recipeJson(
    id: 'tomyum',
    name: 'ต้มยำกุ้ง',
    category: 'ต้ม',
    rating: 4.8,
    cookTimeMinutes: 25,
    difficulty: 'ปานกลาง',
    ingredients: ['กุ้ง', 'ตะไคร้'],
  ),
  recipeJson(
    id: 'carbonara',
    name: 'Carbonara',
    category: 'เส้น',
    country: 'อิตาลี',
    rating: 4.2,
    cookTimeMinutes: 20,
    isOfficial: false,
    ingredients: ['เบคอน', 'ไข่'],
  ),
];

void main() {
  late List<http.Request> log;

  RecipeProvider buildProvider({Map<String, RouteHandler> extra = const {}}) {
    final api = fakeApi({'GET /recipes': (_) => jsonResponse(_catalog), ...extra}, log: log);
    return RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    log = [];
  });

  group('init', () {
    test('loads the catalog and builds category/country lists', () async {
      final provider = buildProvider();
      await provider.init();

      expect(provider.isLoading, isFalse);
      expect(provider.allRecipes, hasLength(3));
      // 'ทั้งหมด' first, then unique categories in code-unit order
      expect(provider.categories, ['ทั้งหมด', 'ต้ม', 'อาหารจานเดียว', 'เส้น']);
      expect(provider.countries.first, 'ทั้งหมด');
      expect(provider.getById('tomyum')!.name, 'ต้มยำกุ้ง');
      expect(provider.getById('missing'), isNull);
    });

    test('ends with an empty list when the backend is down', () async {
      final provider = buildProvider(extra: {'GET /recipes': (_) => jsonResponse({'message': 'down'}, 503)});
      await provider.init();

      expect(provider.allRecipes, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });

  group('filteredRecipes', () {
    late RecipeProvider provider;

    setUp(() async {
      provider = buildProvider();
      await provider.init();
    });

    List<String> ids() => provider.filteredRecipes.map((r) => r.id).toList();

    test('sorts by rating (highest first) by default', () {
      expect(ids(), ['tomyum', 'krapao', 'carbonara']);
    });

    test('searches names and ingredients', () {
      provider.updateSearchQuery('กุ้ง');
      expect(ids(), ['tomyum']);

      provider.updateSearchQuery('เบคอน');
      expect(ids(), ['carbonara']);
    });

    test('filters by category, country, source, difficulty and total time', () {
      provider.updateSelectedCategory('ต้ม');
      expect(ids(), ['tomyum']);
      provider.clearFilters();

      provider.updateSelectedCountry('อิตาลี');
      expect(ids(), ['carbonara']);
      provider.clearFilters();

      provider.updateSelectedSource(SourceFilter.user);
      expect(ids(), ['carbonara']);
      provider.clearFilters();

      provider.updateSelectedDifficulty('ปานกลาง');
      expect(ids(), ['tomyum']);
      provider.clearFilters();

      // total time = prep + cook: krapao 15, carbonara 30, tomyum 35
      provider.updateMaxCookTime(30);
      expect(ids(), unorderedEquals(['krapao', 'carbonara']));
    });

    test('supports other sort orders', () {
      provider.updateSortOption(SortOption.timeAsc);
      expect(ids(), ['krapao', 'carbonara', 'tomyum']);

      provider.updateSortOption(SortOption.nameAsc);
      expect(ids().first, 'carbonara');
    });

    test('clearFilters resets everything', () {
      provider
        ..updateSearchQuery('xyz')
        ..updateSelectedCategory('ต้ม')
        ..updateMaxCookTime(1);
      expect(ids(), isEmpty);

      provider.clearFilters();
      expect(ids(), hasLength(3));
      expect(provider.searchQuery, '');
      expect(provider.selectedCategory, 'ทั้งหมด');
    });
  });

  group('favorites', () {
    test('guests toggle favorites locally without calling the API', () async {
      final provider = buildProvider();
      await provider.init();
      await provider.onAuthChanged(false);

      provider.toggleFavorite('krapao');

      expect(provider.isFavorite('krapao'), isTrue);
      expect(provider.favoriteRecipes.single.id, 'krapao');
      expect(log.where((r) => r.url.path.startsWith('/favorites')), isEmpty);
    });

    test('logged-in users load favorites and sync toggles to the backend', () async {
      final provider = buildProvider(extra: {
        'GET /favorites': (_) => jsonResponse(['tomyum']),
        'POST /favorites/krapao': (_) => jsonResponse({}, 201),
      });
      await provider.init();
      await provider.onAuthChanged(true);
      expect(provider.isFavorite('tomyum'), isTrue);

      provider.toggleFavorite('krapao');
      await pumpEventQueue();

      expect(provider.isFavorite('krapao'), isTrue);
      expect(log.any((r) => r.method == 'POST' && r.url.path == '/favorites/krapao'), isTrue);
    });

    test('rolls the toggle back when the backend rejects it', () async {
      final provider = buildProvider(extra: {
        'GET /favorites': (_) => jsonResponse([]),
        'POST /favorites/krapao': (_) => jsonResponse({'message': 'fail'}, 500),
      });
      await provider.init();
      await provider.onAuthChanged(true);

      provider.toggleFavorite('krapao');
      expect(provider.isFavorite('krapao'), isTrue, reason: 'optimistic update');
      await pumpEventQueue();

      expect(provider.isFavorite('krapao'), isFalse);
    });
  });

  group('search history', () {
    test('keeps the newest query first, without duplicates, capped and persisted', () async {
      final provider = buildProvider();
      await provider.init();

      for (var i = 0; i < AppConstants.maxSearchHistory + 2; i++) {
        provider.addToSearchHistory('q$i');
      }
      provider.addToSearchHistory('q5');
      provider.addToSearchHistory('   ');

      expect(provider.searchHistory.first, 'q5');
      expect(provider.searchHistory, hasLength(AppConstants.maxSearchHistory));
      expect(provider.searchHistory.where((q) => q == 'q5'), hasLength(1));

      await pumpEventQueue();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('search_history')!.first, 'q5');
    });
  });

  group('recipe CRUD', () {
    test('addRecipe puts the created recipe first', () async {
      final provider = buildProvider(extra: {
        'POST /recipes': (_) => jsonResponse(recipeJson(id: 'new', name: 'ข้าวผัด', isOfficial: false), 201),
      });
      await provider.init();

      final error = await provider.addRecipe(
        name: 'ข้าวผัด',
        emoji: '🍚',
        category: 'อาหารจานเดียว',
        country: 'ไทย',
        prepTime: 5,
        cookTime: 10,
        difficulty: 'ง่าย',
        servings: 1,
        steps: const ['ผัด'],
        items: const [IngredientItem(name: 'ข้าว', amount: '1', unit: 'จาน')],
      );

      expect(error, isNull);
      expect(provider.allRecipes.first.id, 'new');
    });

    test('addRecipe returns the backend error and changes nothing', () async {
      final provider = buildProvider(extra: {
        'POST /recipes': (_) => jsonResponse({'message': 'Unauthorized'}, 401),
      });
      await provider.init();

      final error = await provider.addRecipe(
        name: 'x',
        emoji: 'x',
        category: 'x',
        country: 'x',
        prepTime: 0,
        cookTime: 0,
        difficulty: 'ง่าย',
        servings: 1,
        steps: const [],
        items: const [],
      );

      expect(error, 'Unauthorized');
      expect(provider.allRecipes, hasLength(3));
    });

    test('deleteRecipe removes the recipe and its favorite', () async {
      final provider = buildProvider(extra: {'DELETE /recipes/krapao': (_) => jsonResponse(null)});
      await provider.init();
      provider.toggleFavorite('krapao');

      final error = await provider.deleteRecipe('krapao');

      expect(error, isNull);
      expect(provider.getById('krapao'), isNull);
      expect(provider.isFavorite('krapao'), isFalse);
    });

    test('updateRecipe replaces the recipe with the server copy', () async {
      final provider = buildProvider(extra: {
        'PATCH /recipes/krapao': (_) => jsonResponse(recipeJson(id: 'krapao', name: 'กะเพราไก่')),
      });
      await provider.init();

      final original = provider.getById('krapao')!;
      final error = await provider.updateRecipe(original.copyWith(name: 'กะเพราไก่'));

      expect(error, isNull);
      expect(provider.getById('krapao')!.name, 'กะเพราไก่');
    });
  });
}
