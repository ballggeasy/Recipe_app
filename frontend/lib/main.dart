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
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _lastSyncedKey = 'unset';

  void _syncOnAuthChange(AuthProvider auth) {
    final String key;
    final bool isLoggedIn;
    switch (auth.status) {
      case AuthStatus.loggedIn:
        final userId = auth.currentUser?.id;
        if (userId == null) return;
        key = userId;
        isLoggedIn = true;
      case AuthStatus.guest:
        key = 'guest';
        isLoggedIn = false;
      case AuthStatus.loggedOut:
        key = 'loggedOut';
        isLoggedIn = false;
      case AuthStatus.unknown:
        return;
    }

    if (key == _lastSyncedKey) return;
    _lastSyncedKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
      context.read<RecipeProvider>().onAuthChanged(
        isLoggedIn,
        userId: isLoggedIn ? key : null,
      );
      context.read<FavoriteProvider>().onAuthChanged(isLoggedIn);
      context.read<MealPlannerProvider>().onAuthChanged(isLoggedIn);
      context.read<ReviewProvider>().onAuthChanged();
      context.read<CommentProvider>().onAuthChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _syncOnAuthChange(auth);

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
