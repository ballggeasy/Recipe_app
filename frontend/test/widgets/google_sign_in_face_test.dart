import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/social_login_button.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool loading = false,
    ThemeData? theme,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: GoogleSignInFace(onTap: onTap, loading: loading),
        ),
      ),
    ),
  );

  testWidgets('is 52 high, full width and shows the Google logo and label', (
    tester,
  ) async {
    await pump(tester, onTap: () {});

    expect(tester.getSize(find.byType(GoogleSignInFace)).height, 52);
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      tester.getSize(find.byType(GoogleSignInFace)).width,
      screenWidth - 48,
    );
    expect(find.text('ดำเนินการต่อด้วย Google'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GoogleSignInFace),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
      reason: 'the four-colour Google "G"',
    );
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);

    await tester.tap(find.byType(GoogleSignInFace));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('while signing in it shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++, loading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('กำลังเข้าสู่ระบบ…'), findsOneWidget);
    expect(find.text('ดำเนินการต่อด้วย Google'), findsNothing);

    await tester.tap(find.byType(GoogleSignInFace));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('without an onTap it is disabled: faded and not tappable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.5);
    expect(
      tester.getSemantics(find.byType(GoogleSignInFace)),
      matchesSemantics(
        label: 'ดำเนินการต่อด้วย Google',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('is announced as one button named after the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, onTap: () {});

    expect(
      tester.getSemantics(find.byType(GoogleSignInFace)),
      matchesSemantics(
        label: 'ดำเนินการต่อด้วย Google',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('darkens its surface and border in the dark theme', (
    tester,
  ) async {
    BoxDecoration decoration() =>
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(GoogleSignInFace),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;

    await pump(tester, onTap: () {});
    expect(decoration().color, const Color(0xFFFFFFFF));
    expect(decoration().boxShadow, isNotEmpty);

    await pump(tester, onTap: () {}, theme: AppTheme.darkTheme);
    await tester.pumpAndSettle();
    expect(decoration().color, const Color(0xFF211C16));
    expect(decoration().boxShadow, isNull);
  });
}
