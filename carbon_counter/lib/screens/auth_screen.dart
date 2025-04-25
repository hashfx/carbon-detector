import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:carbon_counter/screens/carbon_data_screen.dart';
import 'package:carbon_counter/utils/constants.dart';
// Import the new legal content widget file
import 'package:carbon_counter/widgets/legal_content.dart'; // Adjust path if needed

// --- AuthScreen Widget ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controllers, Keys, State Variables... (Keep these as they were)
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String _dialogAuthErrorMessage = '';
  String? _backgroundImagePath;

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
    } else {/* ... handle empty list ... */}
  }

  @override
  void dispose() {
    _log("dispose: Cleaning up controllers.");
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Dialog Authentication Logic --- (_showAuthDialog, _submitAuthForm, _getAuthErrorMessage, _navigateToCarbonDataScreen)
  // --- KEEP THESE FUNCTIONS EXACTLY AS THEY WERE IN THE PREVIOUS VERSION ---
  // ... (Code for _showAuthDialog) ...
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
            // Simple animation for dialog content appearance
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
                      Theme.of(context).colorScheme.surface.withOpacity(0.1),
                      Theme.of(context).colorScheme.surface.withOpacity(0.2),
                    ],
                    stops: const [0.1, 1],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.5),
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
                                /* ... email field details ... */
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
                                          color: Colors.white.withOpacity(0.5)),
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
                                              .withOpacity(0.7)),
                                      borderRadius: BorderRadius.circular(12)),
                                  focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      color: Colors.white70),
                                ),
                                validator: (value) {
                                  /* ... validator ... */ final v =
                                      value?.trim() ?? '';
                                  if (v.isEmpty)
                                    return 'Please enter your email.';
                                  if (!RegExp(
                                          r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$")
                                      .hasMatch(v))
                                    return 'Please enter a valid email address.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                /* ... password field details ... */
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
                                          color: Colors.white.withOpacity(0.5)),
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
                                              .withOpacity(0.7)),
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
                                  /* ... validator ... */ final v =
                                      value?.trim() ?? '';
                                  if (v.isEmpty)
                                    return 'Please enter your password.';
                                  if (v.length < 6)
                                    return 'Password must be at least 6 characters.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              AnimatedOpacity(
                                /* ... error message ... */ opacity:
                                    _dialogAuthErrorMessage.isNotEmpty
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
                                /* ... submit button ... */ style:
                                    ElevatedButton.styleFrom(
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
                                      .withOpacity(0.8),
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

  // ... (Code for _submitAuthForm) ...
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

  // ... (Code for _getAuthErrorMessage) ...
  String _getAuthErrorMessage(String errorCode) {
    /* ... error messages ... */ _log(
        "getAuthErrorMessage: Formatting error for code: $errorCode");
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

  // ... (Code for _navigateToCarbonDataScreen) ...
  void _navigateToCarbonDataScreen() {
    if (!mounted) return;
    _log("Navigating to CarbonDataScreen...");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CarbonDataScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- NEW: Helper to show legal info (Decides Dialog vs Bottom Sheet) ---
  void _showLegalInfo(BuildContext context, String type) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 650; // Adjusted breakpoint slightly

    if (isSmallScreen) {
      _showDraggableBottomSheet(context, type);
    } else {
      _showCenteredDialog(context, type);
    }
  }

  // --- NEW: Draggable Bottom Sheet Implementation ---
  void _showDraggableBottomSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for flexible height
      enableDrag: true,
      backgroundColor:
          Colors.transparent, // Sheet background is handled by inner container
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Start at 70% height
          minChildSize: 0.3, // Allow dragging down to 30%
          maxChildSize: 0.9, // Allow dragging up to 90%
          expand: false,
          builder: (BuildContext _, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface, // Or use a slightly different color
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10)
                  ]),
              child: Column(
                children: [
                  // Grab Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  // Content Area
                  Expanded(
                    child: ListView(
                      // Use ListView for scrolling content
                      controller:
                          scrollController, // Link controller for dragging
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 20),
                      children: getLegalContentWidgets(
                          sheetContext, type), // Get content from separate file
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

  // --- NEW: Centered Dialog Implementation ---
  void _showCenteredDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          titlePadding:
              const EdgeInsets.fromLTRB(20, 20, 10, 0), // Adjust padding
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor:
              Theme.of(context).dialogBackgroundColor, // Use theme color
          // Constrain the dialog size on larger screens
          insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width *
                  0.15, // 15% margin on each side
              vertical: MediaQuery.of(context).size.height *
                  0.1 // 10% margin top/bottom
              ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title is generated within getLegalContentWidgets now, so we can omit explicit title here
              // Text(type == 'privacy' ? 'Privacy Policy' : 'Terms of Service'),
              // Instead use a flexible spacer if needed, or remove if title in content is enough
              const Spacer(), // Pushes close button to the right
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // Remove default padding
              ),
            ],
          ),
          content: SizedBox(
            // Ensures content tries to fill available dialog space
            width: double.maxFinite, // Use available width within constraints
            child: SingleChildScrollView(
              // Make content scrollable
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Column takes minimum needed vertical space
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to start
                children: getLegalContentWidgets(
                    dialogContext, type), // Get content from separate file
              ),
            ),
          ),
          actions: <Widget>[
            // Optional: Add close button in actions as well/instead
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

  // --- Build Method (Landing Page) ---
  @override
  Widget build(BuildContext context) {
    _log(
        "build: Rebuilding AuthScreen landing page. Background: $_backgroundImagePath");
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 650; // Using adjusted breakpoint

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
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.75),
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
                    // --- Logo --- (Keep as is)
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
                    // --- App Name --- (Keep as is)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppConstants.itemSpacing),
                      child: Text(
                        'Carbon Shodhak',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
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
                    // --- Tagline --- (Keep as is)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.itemSpacing * 0.75,
                          bottom: AppConstants.sectionSpacing),
                      child: Text(
                        'Track Your Footprint, Grow a Greener Future.',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
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

                    // --- Top Text Block (Headline) --- MODIFIED TO USE LOGO ---
                    _buildInfoBlock(
                      context,
                      // icon: Icons.eco_outlined, // Commented out icon
                      logoPath:
                          'assets/logos/app_logo.png', // <<< YOUR LOGO PATH HERE AGAIN
                      text:
                          'Understand & Reduce Your Carbon Impact with Personalized Insights.',
                      isSmallScreen: isSmallScreen,
                    ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 450.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // --- BUTTONS SECTION --- (Keep as is)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppConstants.itemSpacing * 2,
                      runSpacing: AppConstants.itemSpacing * 1.5,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1_outlined,
                              size: 18),
                          label: const Text('Sign Up'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 18 : 26,
                                  vertical: 14),
                              textStyle: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.bold),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          onPressed: () =>
                              _showAuthDialog(context, mode: 'signup'),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login_outlined, size: 18),
                          label: const Text('Sign In'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 18 : 26,
                                  vertical: 14),
                              textStyle: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.bold),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          onPressed: () =>
                              _showAuthDialog(context, mode: 'signin'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 600.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // --- Bottom Text Block (Explainer) --- MODIFIED TO USE LOGO ---
                    _buildInfoBlock(
                      context,
                      // icon: Icons.groups_outlined, // Commented out icon
                      logoPath:
                          'assets/logos/app_logo.png', // <<< YOUR LOGO PATH HERE AGAIN
                      text:
                          'Join our community, track progress, and discover sustainable habits.',
                      isSmallScreen: isSmallScreen,
                    ).animate().fadeIn(delay: 750.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 750.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    SizedBox(height: screenHeight * 0.06),

                    // --- Footer Links --- MODIFIED onPressed ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _showLegalInfo(context, 'privacy'), // Call helper
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Privacy Policy',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withOpacity(0.7))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text('|',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () =>
                              _showLegalInfo(context, 'terms'), // Call helper
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Terms of Service',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withOpacity(0.7))),
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

  // --- Helper Widget for Logo + Text Info Blocks --- MODIFIED ---
  Widget _buildInfoBlock(BuildContext context,
      {
      // required IconData icon, // Commented out
      required String logoPath, // Added logo path
      required String text,
      required bool isSmallScreen}) {
    final double logoSize = isSmallScreen ? 20 : 24; // Responsive logo size

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.itemSpacing * 1.5,
          vertical: AppConstants.itemSpacing * 1.25),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Use Image.asset for Logo ---
          Image.asset(
            logoPath, // Use the provided path
            height: logoSize,
            width: logoSize, // Ensure aspect ratio is maintained if needed
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.95), // Apply color tint if desired
            colorBlendMode: BlendMode.srcIn, // Apply color tint mode
            errorBuilder: (ctx, err, st) => Icon(
                // Fallback icon if logo fails
                Icons.eco_outlined, // Original fallback icon
                color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                size: logoSize),
          ),
          // Icon( // Original icon commented out
          //   icon,
          //   color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
          //   size: isSmallScreen ? 20 : 24
          // ),
          const SizedBox(width: AppConstants.itemSpacing * 1.25),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.95),
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
