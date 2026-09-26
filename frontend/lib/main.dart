import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/meal_planner_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main/main_screen.dart';
import '../widgets/common/loading_state.dart';

void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => MealPlannerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'สูตรอาหาร',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // _AuthSync อยู่เหนือ Navigator จึงยังทำงานแม้หน้าจอ login/logout จะแทนที่ route ของ _AuthGate ไปแล้ว
            builder: (context, child) => _AuthSync(child: child!),
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// โหลด/ล้างข้อมูลของ provider ที่ผูกกับผู้ใช้ทุกครั้งที่สถานะล็อกอินเปลี่ยน (รวมถึง logout แล้ว login เป็นอีกคน)
class _AuthSync extends StatefulWidget {
  final Widget child;
  const _AuthSync({required this.child});

  @override
  State<_AuthSync> createState() => _AuthSyncState();
}

class _AuthSyncState extends State<_AuthSync> {
  String? _lastSyncedKey = 'unset';

  void _syncOnAuthChange(AuthProvider auth) {
    final String? key;
    final bool isLoggedIn;
    switch (auth.status) {
      case AuthStatus.unknown:
        return;
      case AuthStatus.loggedIn:
        key = auth.currentUser?.id;
        isLoggedIn = true;
      case AuthStatus.guest:
        key = 'guest';
        isLoggedIn = false;
      case AuthStatus.loggedOut:
        key = 'loggedOut';
        isLoggedIn = false;
    }

    if (key == _lastSyncedKey) return;
    _lastSyncedKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecipeProvider>().onAuthChanged(isLoggedIn);
      context.read<FavoriteProvider>().onAuthChanged(isLoggedIn);
      context.read<MealPlannerProvider>().onAuthChanged(isLoggedIn);
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncOnAuthChange(context.watch<AuthProvider>());
    return widget.child;
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.unknown) {
      return Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: const LoadingState(),
      );
    }

    if (auth.status == AuthStatus.loggedIn || auth.status == AuthStatus.guest) {
      return const MainScreen();
    }

    return const LoginScreen();
  }
}
