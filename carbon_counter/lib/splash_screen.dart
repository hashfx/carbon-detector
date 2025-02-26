import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Logo Slide-in Animation
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoSlideAnimation = Tween<double>(
      begin: -300.0, // Start position off-screen to the left
      end: 0.0, // End position at the center (or desired horizontal position)
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOutQuart,
      ),
    );

    _logoAnimationController.forward(); // Start animations

    // Timer for Splash Screen Duration and Navigation
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => CarbonDataScreen()),
      );
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Animated Logo Image (Slide-in)
            AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _logoSlideAnimation.value,
                    0.0,
                  ), // Horizontal translation
                  child: child,
                );
              },
              child: Image.asset(
                // Child widget that gets animated
                'assets/images/carbon_shodhak_logo.png',
                height: 150,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Carbon is in the Air: Tracking the Invisible',
              style: TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
