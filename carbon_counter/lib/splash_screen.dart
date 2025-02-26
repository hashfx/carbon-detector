import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => CarbonDataScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200], // bgColor of splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // title of Splash Screen
            Column(
              children: [
                Text(
                  'Carbon शोधक',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20), // spacing between title and subtitle
            Text(
              'Carbon is in the Air: Tracking the Invisible', // Subtitle
              style: TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 40), // Spacing before the image/icon
            Icon(
              Icons.air, // image
              size: 100,
              color: Colors.green[400],
            ),
            // image from assets
            // Image.asset('assets/images/splash_image.png', height: 150),
          ],
        ),
      ),
    );
  }
}
