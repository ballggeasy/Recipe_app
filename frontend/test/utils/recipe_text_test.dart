import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/utils/recipe_text.dart';

import '../helpers/fake_api.dart';

void main() {
  test('a real video link is opened as given', () {
    final recipe = Recipe.fromApi({
      ...recipeJson(name: 'ผัดกะเพรา'),
      'videoUrl': 'https://example.com/watch',
    });

    expect(recipeVideoUri(recipe).toString(), 'https://example.com/watch');
    expect(recipeDocument(recipe), contains('ผัดกะเพรา'));
    expect(recipeDocument(recipe), contains('ส่วนผสม'));
  });

  test('a placeholder video opens a search for that recipe', () {
    final recipe = Recipe.fromApi({
      ...recipeJson(name: 'ผัดกะเพรา'),
      'videoUrl': 'placeholder://video/pad-krapao',
    });

    final uri = recipeVideoUri(recipe);
    expect(uri.host, 'www.youtube.com');
    expect(uri.queryParameters['search_query'], contains('ผัดกะเพรา'));
    expect(hasRecipeVideo(recipe), isTrue);
  });
}
