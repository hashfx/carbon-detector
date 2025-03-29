import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:carbon_counter/screens/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  tz.initializeTimeZones(); // Initialize timezone data once
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon शोधक App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Optional: Define consistent text themes if needed
        // textTheme: TextTheme(...)
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: const SplashScreen(), // Start with the splash screen
    );
  }
}
