import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:carbon_counter/screens/carbon_data_screen.dart';
import 'package:carbon_counter/utils/constants.dart';
import 'package:carbon_counter/widgets/legal_content.dart'; // Assuming this path is correct

// --- AuthScreen Widget ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // --- Controllers, Keys, State Variables ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String _dialogAuthErrorMessage = '';
  String? _backgroundImagePath;

  // --- State for button press effect ---
  bool _isSignInPressed = false; // For retro button state
  bool _isSignUpPressed = false; // For retro button state

  // --- Logging Helper ---
  void _log(String message) {
    debugPrint('[AuthScreen] ${DateTime.now().toIso8601String()} $message');
  }

  @override
  void initState() {
    super.initState();
    _log("initState: Setting up AuthScreen.");
    _selectRandomBackground();
  }

  // --- _selectRandomBackground --- (Keep as is)
  void _selectRandomBackground() {
    final List<String> images = AppConstants().backgroundImages;
    if (images.isNotEmpty) {
      final random = Random();
      final index = random.nextInt(images.length);
      if (mounted) {
        setState(() {
          if (_backgroundImagePath != images[index] || images.length == 1) {
            _backgroundImagePath = images[index];
          } else {
            final newIndex = (index + 1) % images.length;
            _backgroundImagePath = images[newIndex];
          }
          _log("Selected background image: $_backgroundImagePath");
        });
      }
    } else {
      _log("Warning: backgroundImages list empty.");
      if (mounted) setState(() => _backgroundImagePath = null);
    }
  }

  @override
  void dispose() {
    _log("dispose: Cleaning up controllers.");
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Dialog Authentication Logic ---
  // --- KEEP _showAuthDialog, _submitAuthForm, _getAuthErrorMessage, ---
  // --- _navigateToCarbonDataScreen, _showLegalInfo, _showDraggableBottomSheet, ---
  // --- _showCenteredDialog EXACTLY AS THEY WERE IN THE ORIGINAL CODE ---
  // ... (Paste your existing dialog/auth/legal functions here - NO CHANGES NEEDED) ...
  void _showAuthDialog(BuildContext context, {required String mode}) {
    _emailController.clear();
    _passwordController.clear();
    _isPasswordVisible = false;
    _dialogAuthErrorMessage = '';
    _isSubmitting = false;
    _log("Showing Auth Dialog for mode: $mode");
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return Animate(
              effects: const [
                FadeEffect(duration: Duration(milliseconds: 300)),
                ScaleEffect(begin: Offset(0.95, 0.95), curve: Curves.easeOut)
              ],
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: GlassmorphicContainer(
                  width: 400,
                  height: _dialogAuthErrorMessage.isNotEmpty ? 480 : 450,
                  borderRadius: 20,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                    ],
                    stops: const [0.1, 1],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(stfContext).pop(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                mode == 'signin' ? 'Sign In' : 'Sign Up',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  hintText: 'Enter your email',
                                  hintStyle:
                                      const TextStyle(color: Colors.white54),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.5)),
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      borderRadius: BorderRadius.circular(12)),
                                  errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.7)),
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      color: Colors.white70),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) {
                                    return 'Please enter your email.';
                                  }
                                  if (!RegExp(
                                          r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$")
                                      .hasMatch(v)) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  hintText: 'Enter your password',
                                  hintStyle:
                                      const TextStyle(color: Colors.white54),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.5)),
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      borderRadius: BorderRadius.circular(12)),
                                  errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.7)),
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white70),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => stfSetState(() =>
                                            _isPasswordVisible =
                                                !_isPasswordVisible),
                                  ),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) {
                                    return 'Please enter your password.';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              AnimatedOpacity(
                                opacity: _dialogAuthErrorMessage.isNotEmpty
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: _dialogAuthErrorMessage.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0, bottom: 8.0),
                                        child: Text(
                                          _dialogAuthErrorMessage,
                                          style: TextStyle(
                                              color: Colors.redAccent[100],
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.8),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _submitAuthForm(
                                        mode: mode,
                                        dialogContext: stfContext,
                                        dialogSetState: stfSetState),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white)))
                                    : Text(mode == 'signin'
                                        ? 'Sign In'
                                        : 'Sign Up'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitAuthForm(
      {required String mode,
      required BuildContext dialogContext,
      required StateSetter dialogSetState}) async {
    _log("submitAuthForm: Attempting submission for mode: $mode");
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      _log("submitAuthForm: Form key is null or validation failed.");
      if (dialogContext.mounted) {
        dialogSetState(() {});
      }
      return;
    }
    _log("submitAuthForm: Form validation PASSED.");
    if (_isSubmitting) return;
    if (dialogContext.mounted) {
      dialogSetState(() {
        _isSubmitting = true;
        _dialogAuthErrorMessage = '';
      });
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final bool attemptSignIn = (mode == 'signin');
    try {
      UserCredential userCredential;
      if (attemptSignIn) {
        userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        _log("submitAuthForm: Sign In SUCCESSFUL.");
      } else {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        _log("submitAuthForm: Sign Up SUCCESSFUL.");
      }
      if (!dialogContext.mounted) return;
      if (userCredential.user != null) {
        Navigator.of(dialogContext).pop();
        _navigateToCarbonDataScreen();
      } else {
        if (dialogContext.mounted) {
          dialogSetState(() {
            _dialogAuthErrorMessage =
                "Authentication successful, but failed to retrieve user data.";
            _isSubmitting = false;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      _log("submitAuthForm: Firebase Error. Code: ${e.code}");
      if (!dialogContext.mounted) return;
      final errorMessage = _getAuthErrorMessage(e.code);
      dialogSetState(() {
        _dialogAuthErrorMessage = errorMessage;
        _isSubmitting = false;
      });
    } catch (e, s) {
      _log("submitAuthForm: Unexpected error: $e\nStackTrace: $s");
      if (!dialogContext.mounted) return;
      dialogSetState(() {
        _dialogAuthErrorMessage = 'An unexpected error occurred.';
        _isSubmitting = false;
      });
    } finally {
      if (dialogContext.mounted && _isSubmitting) {
        dialogSetState(() => _isSubmitting = false);
      }
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    _log("getAuthErrorMessage: Formatting error for code: $errorCode");
    switch (errorCode.toLowerCase()) {
      case 'user-not-found':
      case 'auth/user-not-found':
        return 'No user found with this email. Please Sign Up.';
      case 'wrong-password':
      case 'auth/wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
      case 'auth/invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
      case 'auth/email-already-in-use':
        return 'This email is already registered. Please Sign In.';
      case 'weak-password':
      case 'auth/weak-password':
        return 'Password is too weak (at least 6 characters).';
      case 'invalid-email':
      case 'auth/invalid-email':
        return 'The email address format is not valid.';
      case 'network-request-failed':
      case 'auth/network-request-failed':
        return 'Network error. Check connection and try again.';
      case 'too-many-requests':
      case 'auth/too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'user-disabled':
      case 'auth/user-disabled':
        return 'This user account has been disabled.';
      default:
        _log("getAuthErrorMessage: Unhandled error code: $errorCode");
        return 'An authentication error occurred ($errorCode).';
    }
  }

  void _navigateToCarbonDataScreen() {
    if (!mounted) return;
    _log("Navigating to CarbonDataScreen...");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CarbonDataScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showLegalInfo(BuildContext context, String type) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 650;
    if (isSmallScreen) {
      _showDraggableBottomSheet(context, type);
    } else {
      _showCenteredDialog(context, type);
    }
  }

  void _showDraggableBottomSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext _, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 10)
                  ]),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 20),
                      children: getLegalContentWidgets(sheetContext, type),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCenteredDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 10, 0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.15,
              vertical: MediaQuery.of(context).size.height * 0.1),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title text removed to match style, assuming getLegalContentWidgets adds title
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: getLegalContentWidgets(dialogContext, type),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // --- End of Dialog/Auth/Legal functions ---

  // --- Build Method (Landing Page) ---
  @override
  Widget build(BuildContext context) {
    _log(
        "build: Rebuilding AuthScreen landing page. Background: $_backgroundImagePath");
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 650;
    final theme = Theme.of(context); // Get theme data once

    // --- NEW: Define styles for the RETRO button ---
    final double buttonHeight = isSmallScreen ? 52 : 58; // Slightly taller
    final double borderRadiusValue = 12.0; // Less rounded for classic feel
    final borderRadius = BorderRadius.circular(borderRadiusValue);
    final textStyle = TextStyle(
      fontSize: isSmallScreen ? 15 : 17,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        // Subtle text shadow for better readability on texture
        Shadow(
          offset: Offset(1.0, 1.0),
          blurRadius: 2.0,
          color: Colors.black.withValues(alpha: 0.5),
        ),
      ],
    );

    // --- Decoration for the raised button look ---
    BoxDecoration raisedDecoration(bool isHalfPressed) {
      return BoxDecoration(
          borderRadius: borderRadius,
          image: const DecorationImage(
            image:
                AssetImage("assets/textures/wood_texture.jpeg"), // Your texture
            fit: BoxFit.cover,
          ),
          boxShadow: isHalfPressed
              ? []
              : [
                  // Remove shadows when pressed
                  // Outer dark shadow (bottom right)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(3, 3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                  // Inner light shadow (top left) - subtle highlight
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    offset: const Offset(-2, -2),
                    blurRadius: 3,
                    spreadRadius: 0,
                  ),
                ],
          border: Border.all(
            // Add a subtle border
            color: Colors.black.withValues(alpha: 0.2),
            width: 0.5,
          ));
    }

    // --- Decoration for the depressed button look ---
    // Uses an inner shadow effect via Gradient
    BoxDecoration depressedDecoration() {
      return BoxDecoration(
          borderRadius: borderRadius,
          image: DecorationImage(
            // Keep the image
            image: const AssetImage("assets/textures/wood_texture.jpg"),
            fit: BoxFit.cover,
            // REDUCED darkening effect when pressed
            colorFilter: ColorFilter.mode(
                // Colors.black38, // Original
                Colors.black
                    .withValues(alpha: 0.15), // Significantly less dark overlay
                BlendMode.darken),
          ),
          // Inner shadow effect using gradient - Make shadow slightly less intense
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // Colors.black.withValues(alpha: 0.4), // Original darker top-left
              Colors.black.withValues(alpha: 0.25), // Lighter top-left shadow
              Colors.transparent,
              Colors.transparent,
              // Colors.white.withValues(alpha: 0.1), // Original lighter bottom-right
              Colors.white
                  .withValues(alpha: 0.08), // Slightly subtler bottom-right highlight
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.5),
            width: 1.0,
          ));
    }

    return Scaffold(
      body: Stack(
        children: [
          // --- Animated Background --- (Keep as is)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _backgroundImagePath != null
                ? Image.asset(
                    _backgroundImagePath!,
                    key: ValueKey<String>(_backgroundImagePath!),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                          key: const ValueKey('fallback_color'),
                          color: Colors.blueGrey[900]);
                    },
                  )
                : Container(
                    key: const ValueKey('initial_fallback'),
                    color: Colors.blueGrey[900]),
          ),

          // --- Gradient Overlay --- (Keep as is)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // --- Centered Content ---
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen
                      ? AppConstants.screenPadding * 1.5
                      : AppConstants.screenPadding * 3,
                  vertical: AppConstants.screenPadding * 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: screenHeight * 0.05),
                    // --- Logo, App Name, Tagline --- (Keep as is)
                    Image.asset(
                      'assets/logos/app_logo.png',
                      height: isSmallScreen ? 65 : 85,
                      errorBuilder: (ctx, err, st) => Icon(Icons.eco,
                          size: isSmallScreen ? 60 : 70,
                          color: Colors.greenAccent[400]),
                    ).animate().fadeIn(duration: 600.ms).slideY(
                        begin: -0.3,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppConstants.itemSpacing),
                      child: Text(
                        'Carbon Shodhak',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 26 : 32,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 600.ms).slideY(
                        begin: -0.2,
                        delay: 150.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.itemSpacing * 0.75,
                          bottom: AppConstants.sectionSpacing),
                      child: Text(
                        'Track Your Footprint, Grow a Greener Future.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: isSmallScreen ? 15 : 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
                        begin: -0.2,
                        delay: 300.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),
                    SizedBox(height: screenHeight * 0.05),
                    // --- Top Text Block (Headline) --- (Keep as is)
                    _buildInfoBlock(
                      context,
                      logoPath: 'assets/logos/app_logo.png',
                      text:
                          'Understand & Reduce Your Carbon Impact with Personalized Insights.',
                      isSmallScreen: isSmallScreen,
                    ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 450.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // *********************************************
                    // ******** MODIFIED BUTTON SECTION START ********
                    // *********************************************
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth:
                              isSmallScreen ? 300 : 340), // Adjusted width
                      child: ClipRRect(
                        // Use ClipRRect for border radius clipping
                        borderRadius: borderRadius,
                        child: SizedBox(
                          height: buttonHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // --- Sign In Half ---
                              Expanded(
                                child: GestureDetector(
                                  // Use GestureDetector for press states
                                  onTapDown: (_) =>
                                      setState(() => _isSignInPressed = true),
                                  onTapUp: (_) {
                                    setState(() => _isSignInPressed = false);
                                    // Delay slightly before showing dialog for visual feedback
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      if (mounted)
                                        _showAuthDialog(context,
                                            mode: 'signin');
                                    });
                                  },
                                  onTapCancel: () =>
                                      setState(() => _isSignInPressed = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 120), // Faster animation
                                    curve: Curves
                                        .fastOutSlowIn, // Nice curve for press
                                    // Apply raised or depressed decoration based on state
                                    decoration: _isSignInPressed
                                        ? depressedDecoration()
                                        : raisedDecoration(_isSignInPressed),
                                    // Add slight translation when pressed
                                    transform: _isSignInPressed
                                        ? Matrix4.translationValues(
                                            1.5, 1.5, 0.0)
                                        : Matrix4.identity(),
                                    transformAlignment: Alignment.center,
                                    alignment: Alignment.center,
                                    // Content slightly padded from edges
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login_outlined,
                                          size: isSmallScreen ? 18 : 20,
                                          color: Colors.white,
                                          shadows: textStyle
                                              .shadows, // Use same shadow for icon
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          // Use Flexible for text wrapping if needed
                                          child: Text(
                                            'Sign In',
                                            style: textStyle,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // --- Divider ---
                              Container(
                                width: 1.5, // Divider thickness
                                color: Colors.black
                                    .withValues(alpha: 0.4), // Darker divider
                              ),

                              // --- Sign Up Half ---
                              Expanded(
                                child: GestureDetector(
                                  onTapDown: (_) =>
                                      setState(() => _isSignUpPressed = true),
                                  onTapUp: (_) {
                                    setState(() => _isSignUpPressed = false);
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      if (mounted)
                                        _showAuthDialog(context,
                                            mode: 'signup');
                                    });
                                  },
                                  onTapCancel: () =>
                                      setState(() => _isSignUpPressed = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.fastOutSlowIn,
                                    decoration: _isSignUpPressed
                                        ? depressedDecoration()
                                        : raisedDecoration(_isSignUpPressed),
                                    transform: _isSignUpPressed
                                        ? Matrix4.translationValues(
                                            1.5, 1.5, 0.0)
                                        : Matrix4.identity(),
                                    transformAlignment: Alignment.center,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add_alt_1_outlined,
                                          size: isSmallScreen ? 18 : 20,
                                          color: Colors.white,
                                          shadows: textStyle.shadows,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          // Use Flexible for text wrapping if needed
                                          child: Text(
                                            'Sign Up',
                                            style: textStyle,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 600.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),
                    // *******************************************
                    // ******** MODIFIED BUTTON SECTION END ********
                    // *******************************************

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // --- Bottom Text Block (Explainer) --- (Keep as is)
                    _buildInfoBlock(
                      context,
                      logoPath: 'assets/logos/app_logo.png',
                      text:
                          'Join our community, track progress, and discover sustainable habits.',
                      isSmallScreen: isSmallScreen,
                    ).animate().fadeIn(delay: 750.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 750.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    SizedBox(height: screenHeight * 0.06),

                    // --- Footer Links --- (Keep as is)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _showLegalInfo(context, 'privacy'),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Privacy Policy',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.7))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text('|',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => _showLegalInfo(context, 'terms'),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Terms of Service',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.7))),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms, duration: 600.ms),

                    SizedBox(height: screenHeight * 0.02),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Logo + Text Info Blocks --- (Keep as is)
  Widget _buildInfoBlock(BuildContext context,
      {required String logoPath,
      required String text,
      required bool isSmallScreen}) {
    final double logoSize = isSmallScreen ? 20 : 24;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.itemSpacing * 1.5,
          vertical: AppConstants.itemSpacing * 1.25),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Prevent row from taking full width
        children: [
          Image.asset(
            logoPath,
            height: logoSize,
            width: logoSize,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (ctx, err, st) => Icon(Icons.eco_outlined,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                size: logoSize),
          ),
          const SizedBox(width: AppConstants.itemSpacing * 1.25),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: isSmallScreen ? 14 : 16,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} // End of _AuthScreenState
