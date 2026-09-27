import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/recipe_image_picker.dart';

// 1x1 transparent PNG so Image.memory has real image bytes to show
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late List<XFile?> changes;
  late XFile? nextPick;

  Future<void> pumpPicker(WidgetTester tester, {String? currentImageUrl}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: RecipeImagePicker(
              currentImageUrl: currentImageUrl,
              onChanged: changes.add,
              pickImage: () async => nextPick,
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    changes = [];
    nextPick = XFile.fromData(_png, name: 'dish.png', path: 'dish.png');
  });

  testWidgets('shows a placeholder, then a preview of the picked image', (tester) async {
    await pumpPicker(tester);
    expect(find.text('แตะเพื่อเลือกรูปเมนู'), findsOneWidget);

    await tester.tap(find.text('แตะเพื่อเลือกรูปเมนู'));
    await tester.pumpAndSettle();

    expect(changes.single!.name, 'dish.png');
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('แตะเพื่อเลือกรูปเมนู'), findsNothing);
  });

  testWidgets('clearing the picked image reports null and brings back the placeholder', (tester) async {
    await pumpPicker(tester);
    await tester.tap(find.text('แตะเพื่อเลือกรูปเมนู'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ยกเลิกรูปที่เลือก'));
    await tester.pumpAndSettle();

    expect(changes.last, isNull);
    expect(find.text('แตะเพื่อเลือกรูปเมนู'), findsOneWidget);
  });

  testWidgets('does nothing when the user cancels the picker', (tester) async {
    nextPick = null;
    await pumpPicker(tester);

    await tester.tap(find.text('แตะเพื่อเลือกรูปเมนู'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
  });

  testWidgets('rejects images over 5 MB before uploading', (tester) async {
    nextPick = XFile.fromData(Uint8List(5 * 1024 * 1024 + 1), name: 'huge.jpg', path: 'huge.jpg');
    await pumpPicker(tester);

    await tester.tap(find.text('แตะเพื่อเลือกรูปเมนู'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.text('รูปใหญ่เกิน 5 MB กรุณาเลือกรูปอื่น'), findsOneWidget);
  });

  testWidgets('offers to change an existing recipe image', (tester) async {
    await pumpPicker(tester, currentImageUrl: 'https://example.com/pad-thai.jpg');

    expect(find.byTooltip('เปลี่ยนรูปเมนู'), findsOneWidget);
    expect(find.byTooltip('ยกเลิกรูปที่เลือก'), findsNothing);
  });
}
