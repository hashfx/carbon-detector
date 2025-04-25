import 'dart:async';
import 'dart:math'; // For random background selection
import 'dart:ui'; // For ImageFilter.blur

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glassmorphism/glassmorphism.dart'; // For glassmorphic effect
import 'package:flutter_animate/flutter_animate.dart'; // Added for animations

// **IMPORTANT**: Ensure these import paths match your project structure.
import 'package:carbon_counter/screens/carbon_data_screen.dart';
// Import your constants file
import 'package:carbon_counter/utils/constants.dart'; // Corrected path

// --- AuthScreen Widget ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // --- Controllers & Keys ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- State Variables ---
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String _dialogAuthErrorMessage = '';
  String? _backgroundImagePath; // For random background

  // --- Logging Helper ---
  void _log(String message) {
    debugPrint('[AuthScreen] ${DateTime.now().toIso8601String()} $message');
  }

  @override
  void initState() {
    super.initState();
    _log("initState: Setting up AuthScreen.");
    _selectRandomBackground(); // Select initial random background
  }

  // Function to select a random background image
  void _selectRandomBackground() {
    // *** RECOMMENDATION: Make backgroundImages static const in AppConstants ***
    // final List<String> images = AppConstants.authBackgroundImages; // If static const
    final List<String> images =
        AppConstants().backgroundImages; // Using instance variable

    if (images.isNotEmpty) {
      final random = Random();
      final index = random.nextInt(images.length);
      if (mounted) {
        setState(() {
          // Avoid setting the same image consecutively if possible (simple check)
          if (_backgroundImagePath != images[index]) {
            _backgroundImagePath = images[index];
            _log("Selected background image: $_backgroundImagePath");
          } else if (images.length > 1) {
            // If same image selected and more than one image exists, try again
            // This is a basic attempt, could be more robust
            final newIndex = (index + 1) % images.length;
            _backgroundImagePath = images[newIndex];
            _log(
                "Selected background image (avoided repeat): $_backgroundImagePath");
          } else {
            _backgroundImagePath = images[index]; // Only one image, set it
            _log(
                "Selected background image (only one available): $_backgroundImagePath");
          }
        });
      }
    } else {
      _log(
          "Warning: backgroundImages list in AppConstants is empty or not accessible.");
      if (mounted) {
        setState(() {
          _backgroundImagePath = null; // Handle null case in build method
        });
      }
    }
  }

  @override
  void dispose() {
    _log("dispose: Cleaning up controllers.");
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Dialog Authentication Logic --- (No changes needed in this section)
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
                                  final v = value?.trim() ?? '';
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
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty)
                                    return 'Please enter your password.';
                                  if (v.length < 6)
                                    return 'Password must be at least 6 characters.';
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

  // --- Submit Authentication --- (No changes needed in this section)
  Future<void> _submitAuthForm(
      {required String mode,
      required BuildContext dialogContext,
      required StateSetter dialogSetState}) async {
    _log("submitAuthForm: Attempting submission for mode: $mode");
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      _log("submitAuthForm: Form key is null or validation failed.");
      if (dialogContext.mounted) {
        dialogSetState(
            () {}); // Trigger rebuild to potentially resize dialog if validation changed error visibility
      }
      return;
    }
    _log("submitAuthForm: Form validation PASSED.");

    if (_isSubmitting) return; // Prevent double submission

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
        _log("submitAuthForm: Calling Firebase signInWithEmailAndPassword...");
        userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        _log("submitAuthForm: Sign In SUCCESSFUL.");
      } else {
        _log(
            "submitAuthForm: Calling Firebase createUserWithEmailAndPassword...");
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        _log("submitAuthForm: Sign Up SUCCESSFUL.");
      }

      if (!dialogContext.mounted) return; // Check if context still valid

      if (userCredential.user != null) {
        _log(
            "submitAuthForm: User object retrieved. Closing dialog and navigating...");
        Navigator.of(dialogContext).pop();
        _navigateToCarbonDataScreen(); // Use main context
      } else {
        _log("submitAuthForm: Auth successful but user object is null.");
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
      // Ensure flag is reset if still submitting and mounted
      if (dialogContext.mounted && _isSubmitting) {
        dialogSetState(() => _isSubmitting = false);
      }
    }
  }

  // --- Error Message Helper --- (No changes needed)
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

  // --- Navigation Helper --- (No changes needed)
  void _navigateToCarbonDataScreen() {
    if (!mounted) return;
    _log("Navigating to CarbonDataScreen...");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CarbonDataScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- Build Method (Landing Page) ---
  @override
  Widget build(BuildContext context) {
    _log(
        "build: Rebuilding AuthScreen landing page. Background: $_backgroundImagePath");
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Define a breakpoint for responsiveness adjustments
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Stack(
        children: [
          // --- Animated Background ---
          AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 1200), // Slightly longer fade
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _backgroundImagePath != null
                ? Image.asset(
                    _backgroundImagePath!,
                    // Key is crucial for AnimatedSwitcher to detect change
                    key: ValueKey<String>(_backgroundImagePath!),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      _log(
                          "Error loading background image: $_backgroundImagePath. Error: $error");
                      // Provide a fallback container with a color
                      return Container(
                          key: const ValueKey(
                              'fallback_color'), // Key for fallback
                          color: Colors.blueGrey[900]);
                    },
                  )
                // Fallback container if _backgroundImagePath is initially null or list empty
                : Container(
                    key: const ValueKey('initial_fallback'), // Key for fallback
                    color: Colors.blueGrey[900]),
          ),

          // --- Gradient Overlay ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15), // Less opacity at top
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.75), // More opacity at bottom
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
                constraints: const BoxConstraints(
                    maxWidth: 550), // Max width for content
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: screenHeight * 0.05), // Adjust top padding

                    // --- Logo ---
                    // *** Replace with your actual logo asset ***
                    Image.asset(
                      'assets/logos/app_logo.png', // <<<<< YOUR LOGO PATH HERE
                      height: isSmallScreen ? 65 : 85, // Responsive height
                      // Provide a fallback visual if the logo fails to load
                      errorBuilder: (ctx, err, st) => Icon(Icons.eco,
                          size: isSmallScreen ? 60 : 70,
                          color: Colors.greenAccent[400]),
                    ).animate().fadeIn(duration: 600.ms).slideY(
                        begin: -0.3,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    // --- App Name ---
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppConstants.itemSpacing),
                      child: Text(
                        'Carbon Shodhak', // Replace with your actual app name if different
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  isSmallScreen ? 26 : 32, // Responsive size
                              letterSpacing: 0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 600.ms).slideY(
                        begin: -0.2,
                        delay: 150.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    // --- Tagline ---
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.itemSpacing * 0.75,
                          bottom: AppConstants.sectionSpacing),
                      child: Text(
                        'Track Your Footprint, Grow a Greener Future.', // Your tagline
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontSize:
                                  isSmallScreen ? 15 : 17, // Responsive size
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
                        begin: -0.2,
                        delay: 300.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    SizedBox(height: screenHeight * 0.05), // Dynamic spacing

                    // --- Top Text Block (Headline) ---
                    _buildInfoBlock(
                      context,
                      icon: Icons.eco_outlined, // Relevant icon
                      text:
                          'Understand & Reduce Your Carbon Impact with Personalized Insights.',
                      isSmallScreen: isSmallScreen,
                    ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 450.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // --- BUTTONS SECTION (using Wrap for responsiveness) ---
                    Wrap(
                      alignment:
                          WrapAlignment.center, // Center items horizontally
                      spacing: AppConstants.itemSpacing *
                          2, // Horizontal space between buttons
                      runSpacing: AppConstants.itemSpacing *
                          1.5, // Vertical space if buttons wrap
                      children: [
                        // Sign Up Button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1_outlined,
                              size: 18),
                          label: const Text('Sign Up'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 18 : 26,
                                  vertical: 14), // Responsive padding
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
                        // Sign In Button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login_outlined, size: 18),
                          label: const Text('Sign In'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 18 : 26,
                                  vertical: 14), // Responsive padding
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
                    // --- END OF BUTTONS SECTION ---

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // --- Bottom Text Block (Explainer) ---
                    _buildInfoBlock(
                      context,
                      icon: Icons.groups_outlined, // Community icon
                      text:
                          'Join our community, track progress, and discover sustainable habits.',
                      isSmallScreen: isSmallScreen,
                    ).animate().fadeIn(delay: 750.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        delay: 750.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),

                    SizedBox(
                        height: screenHeight *
                            0.06), // Dynamic spacing before footer

                    // --- Footer Links ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            _log(
                                "Privacy Policy tapped"); /* TODO: Implement navigation/link */
                          },
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
                          onPressed: () {
                            _log(
                                "Terms of Service tapped"); /* TODO: Implement navigation/link */
                          },
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
                    ).animate().fadeIn(
                        delay: 900.ms, duration: 600.ms), // Fade in footer last

                    SizedBox(
                        height: screenHeight * 0.02), // Dynamic bottom padding
                  ],
                ).animate().fadeIn(
                    duration: 300.ms), // Overall fade for the column content
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Icon + Text Info Blocks ---
  Widget _buildInfoBlock(BuildContext context,
      {required IconData icon,
      required String text,
      required bool isSmallScreen}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.itemSpacing * 1.5,
          vertical: AppConstants.itemSpacing * 1.25),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // Slightly increased opacity
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withOpacity(0.1), width: 0.5) // Subtle border
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            MainAxisSize.min, // Row takes minimum needed horizontal space
        children: [
          Icon(icon,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.9), // Brighter icon
              size: isSmallScreen ? 20 : 24 // Responsive icon size
              ),
          const SizedBox(
              width: AppConstants.itemSpacing * 1.25), // Slightly more space
          Flexible(
            // Allows text to wrap within the row's constraints
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.95), // Brighter text
                    fontSize: isSmallScreen ? 14 : 16, // Responsive font size
                    height: 1.4, // Line height
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} // End of _AuthScreenState
