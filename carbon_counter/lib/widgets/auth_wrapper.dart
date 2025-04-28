import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carbon_counter/screens/auth_screen.dart';
import 'package:carbon_counter/screens/navigation_container.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const AuthWrapper({
    Key? key,
    required this.child,
    this.requireAuth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Add a small delay to ensure proper widget disposal
        if (snapshot.connectionState == ConnectionState.active) {
          if (requireAuth) {
            if (snapshot.hasData) {
              return FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: child,
              );
            } else {
              return FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: const AuthScreen(),
              );
            }
          } else {
            if (snapshot.hasData) {
              return FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: const NavigationContainer(),
              );
            } else {
              return FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: child,
              );
            }
          }
        }
        
        // Show a transparent widget while transitioning
        return const SizedBox.shrink();
      },
    );
  }
}