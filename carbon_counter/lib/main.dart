// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carbon_counter/screens/auth_screen.dart';
import 'package:carbon_counter/screens/navigation_container.dart';
import 'package:carbon_counter/firebase_options.dart';
import 'package:carbon_counter/screens/splash_screen.dart';
import 'package:carbon_counter/screens/settings_screen.dart';
import 'package:carbon_counter/widgets/auth_wrapper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:carbon_counter/services/settings_service.dart'; // Import SettingsService

// --- Global Theme Notifier ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// --- Global Settings Service Instance ---
final SettingsService settingsService = SettingsService();

// --- Custom Dark Colors ---
const Color darkBackgroundColor =
    Color(0xFF121212); // Material Design standard dark
const Color darkSurfaceColor = Color(0xFF1E1E1E); // Slightly lighter surface
const Color darkCardColor = Color(0xFF212121); // Card color
const Color darkAppBarColor = Color(0xFF1F1F1F); // AppBar color

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: defaultFirebaseOptions);
  await settingsService.init();
  themeNotifier.value = settingsService.getThemeMode();
  print("Initial ThemeMode set to: ${themeNotifier.value}");
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        print("Building MyApp with ThemeMode: $currentMode");
        return MaterialApp(
          title: 'Carbon शोधक App',

          // --- Define Themes ---
          theme: ThemeData(
            // Light Theme
            brightness: Brightness.light,
            // --- NEW COLOR SCHEME: BlueGrey ---
            primarySwatch: Colors.blueGrey, // Changed from Indigo
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blueGrey, // Changed from Indigo
              accentColor: Colors.amber.shade700, // Using Amber accent
              brightness: Brightness.light,
            ).copyWith(
              secondary: Colors.amber.shade700, // Ensure secondary color is set
              onSecondary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black87,
              background: Colors.grey[100],
              onBackground: Colors.black87,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[100],
            cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blueGrey[600], // Use primary color shade
              foregroundColor: Colors.white,
              elevation: 1.0,
            ),
            chipTheme: ChipThemeData(
              // Base chip theme (overridden in DataChips)
              backgroundColor: Colors.blueGrey.shade100,
              labelStyle: TextStyle(color: Colors.black87),
              iconTheme: IconThemeData(color: Colors.blueGrey.shade800),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
            dataTableTheme: DataTableThemeData(
              // Consistent table divider
              dividerThickness: 1.0,
              horizontalMargin: 12,
              columnSpacing: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 55,
            ),
          ),
          darkTheme: ThemeData(
            // Dark Theme
            brightness: Brightness.dark,
            // --- NEW COLOR SCHEME: BlueGrey ---
            primarySwatch: Colors.blueGrey, // Changed from Indigo
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blueGrey, // Changed from Indigo
              accentColor: Colors.amberAccent, // Using Amber accent
              brightness: Brightness.dark,
            ).copyWith(
              secondary: Colors.amberAccent, // Ensure secondary color is set
              onSecondary: Colors.black,
              // --- Custom Dark Surface/Background Colors ---
              surface: darkSurfaceColor, // Custom dark surface
              onSurface: Colors.white.withOpacity(0.9),
              background: darkBackgroundColor, // Custom dark background
              onBackground: Colors.white.withOpacity(0.9),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor:
                darkBackgroundColor, // Use custom dark background
            cardTheme: CardTheme(
                color: darkCardColor, // Use custom dark card color
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            appBarTheme: AppBarTheme(
              backgroundColor: darkAppBarColor, // Use custom dark AppBar color
              foregroundColor: Colors.white,
              elevation: 0.0, // Flat AppBar in dark theme often looks good
            ),
            chipTheme: ChipThemeData(
              // Base chip theme (overridden in DataChips)
              backgroundColor: Colors.blueGrey.withOpacity(0.3),
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
              iconTheme: IconThemeData(color: Colors.blueGrey.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
            dataTableTheme: DataTableThemeData(
              // Consistent table divider
              dividerThickness: 1.0,
              headingTextStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
              dataTextStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
              horizontalMargin: 12,
              columnSpacing: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 55,
            ),
          ),

          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/auth':
                return MaterialPageRoute(
                  builder: (context) => AuthWrapper(
                    requireAuth: false,
                    child: AuthScreen(),
                  ),
                );
              case '/home':
                return MaterialPageRoute(
                  builder: (context) => AuthWrapper(
                    child: NavigationContainer(),
                  ),
                );
              case '/settings':
                return MaterialPageRoute(
                  builder: (context) => AuthWrapper(
                    child: SettingsScreen(),
                  ),
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
