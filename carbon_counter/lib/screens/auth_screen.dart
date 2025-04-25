import 'dart:async';
import 'dart:math'; // Re-added for random background selection
import 'dart:ui'; // For ImageFilter.blur

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glassmorphism/glassmorphism.dart'; // For glassmorphic effect

// **IMPORTANT**: Ensure these import paths match your project structure.
import 'package:carbon_counter/screens/carbon_data_screen.dart';
// Import your constants file
import 'package:carbon_counter/utils/constants.dart'; // Corrected path based on typical structure

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
  String? _backgroundImagePath; // Re-added for random background

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
    // Accessing the instance variable backgroundImages from AppConstants
    // *** RECOMMENDATION: Make backgroundImages static const in AppConstants ***
    // If static: final List<String> images = AppConstants.authBackgroundImages; (assuming you rename it)
    // If instance (as provided):
    final List<String> images = AppConstants().backgroundImages;

    if (images.isNotEmpty) {
      final random = Random();
      final index = random.nextInt(images.length);
      // Check if mounted before calling setState, especially if this could
      // potentially be called from an async context later (though not here in initState).
      if (mounted) {
        setState(() {
          _backgroundImagePath = images[index];
          _log("Selected background image: $_backgroundImagePath");
        });
      }
    } else {
      _log(
          "Warning: backgroundImages list in AppConstants is empty or not accessible.");
      // Optionally set a default fallback image/color if the list is empty
      if (mounted) {
        setState(() {
          _backgroundImagePath =
              null; // Or set to a default like AppConstants.mainScreenBackgroundImage
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
    // Reset state specific to the dialog each time it opens
    _emailController.clear();
    _passwordController.clear();
    _isPasswordVisible = false;
    _dialogAuthErrorMessage = '';
    _isSubmitting = false; // Ensure loading state is reset

    _log("Showing Auth Dialog for mode: $mode");

    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage state local to the dialog
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              backgroundColor: Colors.transparent, // Needed for glassmorphism
              contentPadding:
                  EdgeInsets.zero, // Control padding via GlassmorphicContainer
              content: GlassmorphicContainer(
                width: 400, // Adjust width as needed
                // Consider making height dynamic based on content or screen size
                height: _dialogAuthErrorMessage.isNotEmpty
                    ? 480
                    : 450, // Adjust height based on error msg
                borderRadius: 20,
                blur: 15, // Blur intensity
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
                    // Close Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(stfContext).pop(),
                      ),
                    ),
                    // Form Content
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Form(
                        key: _formKey, // Use the main form key
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
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              style: const TextStyle(
                                  color: Colors.white), // Text color
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.redAccent.withOpacity(0.7)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.redAccent),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: Colors.white70),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty)
                                  return 'Please enter your email.';
                                if (!RegExp(
                                        r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$")
                                    .hasMatch(v)) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Password Field
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.redAccent.withOpacity(0.7)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.redAccent),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white70,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          // Use stfSetState to update only the dialog's state
                                          stfSetState(() => _isPasswordVisible =
                                              !_isPasswordVisible);
                                        },
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
                            const SizedBox(height: 10), // Reduced space
                            // Error Message Area within Dialog
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
                                          color: Colors.redAccent[
                                              100], // Lighter red for dark bg
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : const SizedBox
                                      .shrink(), // Takes no space when hidden
                            ),
                            const SizedBox(height: 15), // Space before button
                            // Submit Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                                  : () {
                                      _submitAuthForm(
                                          mode: mode,
                                          dialogContext: stfContext,
                                          dialogSetState: stfSetState);
                                    },
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      mode == 'signin' ? 'Sign In' : 'Sign Up'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    if (form == null) {
      _log("submitAuthForm: Form key is null!");
      return;
    }

    // Clear previous dialog errors before validation
    // Check if mounted before calling setState
    if (dialogContext.mounted) {
      dialogSetState(() {
        _dialogAuthErrorMessage = '';
      });
    }

    if (!form.validate()) {
      _log("submitAuthForm: Form validation failed.");
      // Ensure dialog height adjusts if error appears/disappears due to validation
      if (dialogContext.mounted) {
        dialogSetState(() {}); // Trigger rebuild to potentially resize dialog
      }
      return;
    }
    _log("submitAuthForm: Form validation PASSED.");

    // Prevent double submission
    if (_isSubmitting) {
      _log("submitAuthForm: Submission blocked. Already submitting.");
      return;
    }

    // Set submitting state using the dialog's setState
    if (dialogContext.mounted) {
      dialogSetState(() {
        _isSubmitting = true;
        _dialogAuthErrorMessage = ''; // Clear errors again just in case
      });
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final bool attemptSignIn = (mode == 'signin');

    try {
      UserCredential userCredential;
      if (attemptSignIn) {
        _log("submitAuthForm: Calling Firebase signInWithEmailAndPassword...");
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        _log("submitAuthForm: Sign In SUCCESSFUL.");
      } else {
        _log(
            "submitAuthForm: Calling Firebase createUserWithEmailAndPassword...");
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _log("submitAuthForm: Sign Up SUCCESSFUL.");
      }

      // Check if dialog's context is still valid
      if (!dialogContext.mounted) {
        _log(
            "submitAuthForm: Dialog context unmounted after successful Firebase call. Aborting navigation.");
        return;
      }

      if (userCredential.user != null) {
        _log(
            "submitAuthForm: User object retrieved. Closing dialog and navigating...");
        // 1. Close the dialog FIRST
        Navigator.of(dialogContext).pop();
        // 2. THEN Navigate to the main screen (using the original screen's context)
        _navigateToCarbonDataScreen();
      } else {
        _log("submitAuthForm: Auth successful but user object is null.");
        if (dialogContext.mounted) {
          dialogSetState(() {
            _dialogAuthErrorMessage =
                "Authentication successful, but failed to retrieve user data.";
            _isSubmitting = false; // Reset submitting flag
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      _log(
          "submitAuthForm: Firebase Error during submission. Code: ${e.code}, Message: ${e.message}");
      if (!dialogContext.mounted) {
        _log(
            "submitAuthForm: Dialog context unmounted after Firebase error. Aborting state update.");
        return;
      }

      final errorMessage = _getAuthErrorMessage(e.code);
      dialogSetState(() {
        _dialogAuthErrorMessage = errorMessage;
        _isSubmitting = false; // Reset submitting flag
      });
    } catch (e, s) {
      _log(
          "submitAuthForm: Unexpected error during submission: $e\nStackTrace: $s");
      if (!dialogContext.mounted) {
        _log(
            "submitAuthForm: Dialog context unmounted after unexpected error. Aborting state update.");
        return;
      }
      dialogSetState(() {
        _dialogAuthErrorMessage = 'An unexpected error occurred.';
        _isSubmitting = false; // Reset submitting flag
      });
    } finally {
      if (dialogContext.mounted && _isSubmitting) {
        _log(
            "submitAuthForm (finally): Resetting _isSubmitting flag via dialogSetState.");
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
    if (!mounted) {
      _log("navigateToCarbonDataScreen: Aborted. Component unmounted.");
      return;
    }
    _log("Navigating to CarbonDataScreen...");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CarbonDataScreen()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  // --- Build Method (Landing Page) ---
  @override
  Widget build(BuildContext context) {
    _log(
        "build: Rebuilding AuthScreen landing page. Background: $_backgroundImagePath");

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          if (_backgroundImagePath != null)
            Positioned.fill(
              child: Image.asset(
                _backgroundImagePath!, // Use the state variable
                key: ValueKey(
                    _backgroundImagePath), // Add key to force image reload on change
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  _log(
                      "Error loading background image: $_backgroundImagePath. Error: $error");
                  return Container(
                      color: Colors.blueGrey[900]); // Darker fallback
                },
              ),
            )
          else
            // Fallback if no image path is set or list was empty
            Container(color: Colors.blueGrey[900]), // Darker fallback

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Centered Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding * 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 550), // Slightly wider max width
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Removed crossAxisAlignment: CrossAxisAlignment.stretch
                  children: <Widget>[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    // Top Text Container
                    Container(
                      padding:
                          const EdgeInsets.all(AppConstants.sectionSpacing),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Welcome! Track your carbon footprint and contribute to a greener planet.',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.4,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // --- MODIFIED BUTTONS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Center the buttons horizontally
                      // mainAxisSize: MainAxisSize.min, // Let row take minimum space (might not be needed if centered)
                      children: [
                        // Sign Up Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              // Padding adjusted for smaller size
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold), // Slightly smaller font
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          onPressed: () {
                            _showAuthDialog(context, mode: 'signup');
                          },
                          child: const Text('Sign Up'),
                        ),

                        // Gap between buttons
                        const SizedBox(
                            width: AppConstants.itemSpacing *
                                2), // Use constant for gap

                        // Sign In Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              // Padding adjusted for smaller size
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold), // Slightly smaller font
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          onPressed: () {
                            _showAuthDialog(context, mode: 'signin');
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                    // --- END OF MODIFIED BUTTONS SECTION ---

                    const SizedBox(height: AppConstants.sectionSpacing * 2.5),

                    // Bottom Text Container
                    Container(
                      padding:
                          const EdgeInsets.all(AppConstants.sectionSpacing),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Join our community today and make a difference, one step at a time.',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.4,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
