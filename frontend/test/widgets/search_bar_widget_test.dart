// ช่องค้นหาต้องแสดงคำค้นเดียวกับที่ใช้กรองจริง แม้คำค้นถูกเปลี่ยนจากที่อื่น (ชิปประวัติ, ล้างตัวกรอง, อีกแท็บ)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/widgets/search/search_bar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('field text follows provider.searchQuery changes made elsewhere', (tester) async {
    final api = fakeApi({'GET /recipes': (_) => jsonResponse([recipeJson()])});
    final provider = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: SearchBarWidget(showHistory: true))),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ไก่');
    await tester.pump();
    expect(provider.searchQuery, 'ไก่');

    provider.clearFilters();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    provider.addToSearchHistory('หมู');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'หมู'));
    await tester.pumpAndSettle();
    expect(provider.searchQuery, 'หมู');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'หมู');
  });
}
