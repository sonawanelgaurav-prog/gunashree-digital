import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens.dart';
import 'services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(ApiService());
  await state.bootstrap();
  runApp(GunashreeApp(state: state));
}

class GunashreeApp extends StatelessWidget {
  const GunashreeApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17132B);
    const violet = Color(0xFF6D4AFF);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Gunashree Digital',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8F7FC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: violet,
              brightness: Brightness.light,
              surface: const Color(0xFFF8F7FC),
            ),
            fontFamily: 'sans',
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: ink,
              ),
              headlineSmall: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: ink,
              ),
              titleLarge: TextStyle(
                fontWeight: FontWeight.w800,
                color: ink,
              ),
              titleMedium: TextStyle(
                fontWeight: FontWeight.w700,
                color: ink,
              ),
              bodyMedium: TextStyle(
                height: 1.45,
                color: Color(0xFF625E72),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              foregroundColor: ink,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: violet.withValues(alpha: 0.13),
              labelTextStyle: WidgetStatePropertyAll(
                TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: ink),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8E5F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: violet, width: 1.4),
              ),
            ),
          ),
          home: AppShell(state: state),
        );
      },
    );
  }
}
