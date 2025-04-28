// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:carbon_counter/screens/auth_screen.dart';
// import 'package:carbon_counter/screens/carbon_data_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation; // Added fade animation

  @override
  void initState() {
    super.initState();

    // Logo Animations
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Slightly faster
      vsync: this,
    );

    // Slide Animation (starts slightly off-screen below, moves up)
    _logoSlideAnimation = Tween<double>(
      begin: 50.0, // Start below center
      end: 0.0, // End at center
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        // curve: Curves.easeInOutQuart,
        curve: Curves.elasticOut, // Bouncy effect
      ),
    );

    // Fade-in Animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0, // Start fully transparent
      end: 1.0, // End fully opaque
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.7,
            curve: Curves.easeIn), // Fade in during first 70%
      ),
    );

    _logoAnimationController.forward(); // Start animations

    // Timer for Splash Screen Duration and Navigation Check
    Timer(const Duration(seconds: 3), () {
      // Reduced duration slightly
      _checkAuthStatusAndNavigate();
    });
  }

  Future<void> _checkAuthStatusAndNavigate() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is signed in -> Navigate to NavigationContainer
      print("User is signed in: ${user.uid}");
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User is NOT signed in -> Navigate to AuthScreen
      print("User is not signed in.");
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a theme-aware background or a gradient
    final theme = Theme.of(context);
    return Scaffold(
      // backgroundColor: Colors.blue[200], // Original
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondary.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Animated Logo Image (Slide + Fade)
              AnimatedBuilder(
                animation: _logoAnimationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(
                        0.0, // No horizontal slide in this version
                        _logoSlideAnimation.value, // Vertical translation
                      ),
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  // Child widget that gets animated
                  // Ensure this path is correct in your project
                  'assets/images/carbon_shodhak_logo.png', // Updated path based on auth_screen
                  height: 130, // Slightly smaller
                  errorBuilder: (ctx, err, st) =>
                      Icon(Icons.eco, size: 120, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 25),
              // Fade in the text after the logo animation starts
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _logoAnimationController,
                  curve: const Interval(0.5, 1.0,
                      curve: Curves.easeIn), // Fade in during second half
                ),
                child: const Text(
                  'Carbon शोधक', // App name
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 2,
                          color: Colors.black38,
                          offset: Offset(1, 1))
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _logoAnimationController,
                  curve: const Interval(0.6, 1.0,
                      curve: Curves.easeIn), // Fade in later
                ),
                child: Text(
                  'Tracking the Invisible...', // Tagline
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
