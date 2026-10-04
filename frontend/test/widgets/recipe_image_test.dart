import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/recipe_image.dart';

Recipe _recipe({required String imageUrl}) => Recipe(
  id: 'r1',
  name: 'ส้มตำไทย',
  emoji: '🥗',
  imageUrl: imageUrl,
  category: 'จานเดียว',
  cookTimeMinutes: 10,
  difficulty: 'ง่าย',
  ingredients: const [],
  steps: const [],
  country: 'ไทย',
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pump(WidgetTester tester, Recipe recipe) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 200,
          child: RecipeImage(recipe: recipe),
        ),
      ),
    ),
  );

  group('bundledPhotoFor', () {
    test('maps every sample Wikimedia URL to a photo that ships with the app', () {
      const urls = [
        'https://upload.wikimedia.org/x/Kapow_and_egg.jpg',
        'https://upload.wikimedia.org/x/Tom_yum_kung_mae_nam.jpg',
        'https://upload.wikimedia.org/x/Korean.fried.chicken.jpg',
        'https://upload.wikimedia.org/x/Kimchi_jjigae.jpg',
        'https://upload.wikimedia.org/x/Tteokbokki_02.jpg',
        'https://upload.wikimedia.org/x/Bibimbap_салат.jpg',
        'https://upload.wikimedia.org/x/Pot-stickers.jpg',
        'https://upload.wikimedia.org/x/Sweet_and_sour_pork.jpg',
        'https://upload.wikimedia.org/x/Salted_egg_fried_rice.jpg',
        'https://upload.wikimedia.org/x/Takoyaki_in_Osaka.jpg',
        'https://upload.wikimedia.org/x/Salmon_and_shrimp_don_by_jetalone.jpg',
        'https://upload.wikimedia.org/x/Shoyu_ramen%2C_at_Kasukabe.jpg',
        'https://upload.wikimedia.org/x/Tiramisu_with_all_the_layers.jpg',
        'https://upload.wikimedia.org/x/Eq_it-na_pizza-margherita_sep2005_sml.jpg',
        'https://upload.wikimedia.org/x/Fresh_made_pasta_Carbonara.jpg',
        'https://upload.wikimedia.org/x/Som_tam_thai.jpg',
      ];
      final assets = <String>{};
      for (final url in urls) {
        final asset = RecipeImage.bundledPhotoFor(url);
        expect(asset, isNotNull, reason: url);
        expect(File(asset!).existsSync(), isTrue, reason: asset);
        assets.add(asset);
      }
      expect(assets, hasLength(urls.length));
    });

    test('leaves uploaded and unknown images alone', () {
      expect(RecipeImage.bundledPhotoFor(''), isNull);
      expect(RecipeImage.bundledPhotoFor('http://host/uploads/abc.jpg'), isNull);
    });
  });

  testWidgets('shows the bundled photo for a sample recipe', (tester) async {
    await pump(
      tester,
      _recipe(imageUrl: 'https://upload.wikimedia.org/x/Som_tam_thai.jpg'),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, endsWith('som_tum.jpg'));
  });

  testWidgets('without a photo it shows an icon, never the emoji', (
    tester,
  ) async {
    await pump(tester, _recipe(imageUrl: ''));
    expect(find.text('🥗'), findsNothing);
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
  });
}
