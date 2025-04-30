import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carbon_counter/screens/auth_screen.dart';

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
        if (snapshot.connectionState == ConnectionState.active) {
          final bool isAuthenticated = snapshot.hasData;

          if (requireAuth && !isAuthenticated) {
            // If authentication is required but user is not authenticated,
            // redirect to auth screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/auth');
            });
            return const SizedBox.shrink();
          } else if (!requireAuth && isAuthenticated) {
            // If authentication is not required (we're on auth screen) 
            // but user is authenticated, redirect to home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home');
            });
            return const SizedBox.shrink();
          }

          // In all other cases, show the intended child
          return child;
        }
        
        // Show a loading indicator while checking auth state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}