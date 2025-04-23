import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carbon_counter/screens/auth_screen.dart';
import 'package:carbon_counter/screens/carbon_data_screen.dart';
import 'package:carbon_counter/firebase_options.dart';
import 'package:carbon_counter/screens/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: defaultFirebaseOptions, // Use your manually created options
  );

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
      home: const AuthScreen(), // Start with the Authentication screen
      initialRoute: '/auth', // Start with the auth screen
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/carbon_data':
            (context) => const CarbonDataScreen(), // Your main screen
      },
    );
  }
}
