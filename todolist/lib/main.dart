import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/services/api_client.dart';
import 'providers/auth_provider.dart';
import 'core/providers/legacy_providers.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale data
  await initializeDateFormatting('vi_VN', null);
  Intl.defaultLocale = 'vi_VN';
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize API client
  apiClient.initialize();
  
  // Setup 401 handler
  apiClient.onUnauthorized = () {
    // This will be called when API returns 401
    // The navigation will be handled by AuthProvider listening to state
    print('🚨 API returned 401 - User will be logged out');
  };
  
  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CollabTaskApp(),
    ),
  );
}

class CollabTaskApp extends StatelessWidget {
  const CollabTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider(
      // Legacy providers for screens not yet migrated to Riverpod
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => TaskProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: legacy_provider.Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'CollabTask - AI Task Management',
            debugShowCheckedModeBanner: false,
            locale: const Locale('vi', 'VN'),
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // ✅ Sử dụng theme từ ThemeProvider để dark mode hoạt động
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6C63FF),
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.interTextTheme(),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6C63FF),
                brightness: Brightness.dark,
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              useMaterial3: true,
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            // ✅ Routes cho navigation
            routes: {
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
