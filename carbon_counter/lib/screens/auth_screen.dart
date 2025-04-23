import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// **IMPORTANT**: Ensure this import path matches your project structure.
import 'package:carbon_counter/screens/carbon_data_screen.dart'; // Assuming this exists

enum EmailCheckStatus { idle, checking, exists, notFound, error }

// --- Parent Widget Consideration ---
// ** VERY IMPORTANT FOR STATE PERSISTENCE **
// If the parent widget containing AuthScreen rebuilds often, you ABSOLUTELY MUST
// provide a Key to AuthScreen to prevent its state (_AuthScreenState) from being lost.
// Example: AuthScreen(key: ValueKey('uniqueAuthScreenKey_preserveState'))
// Failure to do this is a VERY common cause of the UI seemingly resetting
// (e.g., showing "Sign Up" after an email check found an existing user).
// --- End Parent Widget Consideration ---

class AuthScreen extends StatefulWidget {
  // ** VERY IMPORTANT: Add the Key parameter if needed based on parent widget behavior **
  const AuthScreen({super.key /* required Key key */});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  String _authSubmitStatusMessage = '';
  String _welcomeMessage = '';
  EmailCheckStatus _emailCheckStatus = EmailCheckStatus.idle;
  Timer? _debounceTimer;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  bool _isCheckInProgress = false; // Tracks if fetchSignInMethods is running
  String?
  _lastCheckedEmail; // Email for which the last NON-ERROR check completed

  // --- Logging Helper ---
  void _log(String message) {
    // Use debugPrint for better console output handling in Flutter
    debugPrint('[AuthScreen] ${DateTime.now().toIso8601String()} $message');
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _log(
      "initState: Listener added. Initial State: status=$_emailCheckStatus, lastChecked=$_lastCheckedEmail",
    );
  }

  @override
  void dispose() {
    _log("dispose: Cleaning up.");
    _debounceTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _debounceTimer?.cancel(); // Cancel any previous timer
    final trimmedEmail = _emailController.text.trim();
    _log(
      "onEmailChanged: Email -> '$trimmedEmail'. Current Status=$_emailCheckStatus, Checking=$_isCheckInProgress, LastChecked=$_lastCheckedEmail",
    );

    // --- **Reset State Logic** ---
    if (trimmedEmail.isEmpty) {
      // Only reset if the state is not already idle or if messages exist
      if (_emailCheckStatus != EmailCheckStatus.idle ||
          _welcomeMessage.isNotEmpty ||
          _authSubmitStatusMessage.isNotEmpty) {
        _log("onEmailChanged: Email is empty. RESETTING state to idle.");
        if (mounted) {
          // Clear password immediately when email is cleared
          _passwordController.clear();
          setState(() {
            _welcomeMessage = '';
            _authSubmitStatusMessage = '';
            _emailCheckStatus = EmailCheckStatus.idle;
            _isPasswordVisible = false;
            _lastCheckedEmail = null; // Clear the last checked email
            if (_isCheckInProgress) {
              // This shouldn't happen if logic is sound, but as a safeguard:
              _log(
                "onEmailChanged: WARNING - Resetting state while _isCheckInProgress was true!",
              );
              _isCheckInProgress = false;
            }
          });
        }
      } else {
        _log(
          "onEmailChanged: Email empty, but state already idle. No reset needed.",
        );
      }
      return; // Stop further processing if email is empty
    }

    // --- **Trigger New Check (via Debounce)?** ---
    final bool isFormatValid = RegExp(
      r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
    ).hasMatch(trimmedEmail);
    // Trigger check ONLY if: format is valid, it's a NEW email compared to the last successful check, AND no check is currently running.
    final bool isNewEmailToCheck = trimmedEmail != _lastCheckedEmail;
    final bool shouldStartDebounce =
        isFormatValid && isNewEmailToCheck && !_isCheckInProgress;

    if (shouldStartDebounce) {
      _log(
        "onEmailChanged: Conditions met to start debounce for '$trimmedEmail'. [Format:$isFormatValid, New:$isNewEmailToCheck, NotChecking:${!_isCheckInProgress}]",
      );
      _debounceTimer = Timer(const Duration(milliseconds: 900), () {
        // --- Inside Debounce Timer Callback ---
        // Re-read email value WHEN TIMER FIRES, as it might have changed again
        final emailAtDebounceTime = _emailController.text.trim();
        _log(
          "onEmailChanged (debounce): Timer fired. Email now: '$emailAtDebounceTime'. Checking against original: '$trimmedEmail'",
        );

        // Check if still mounted, if a check isn't already running (extra safety),
        // and if the email is still the same valid one we intended to check.
        if (mounted &&
            !_isCheckInProgress &&
            emailAtDebounceTime == trimmedEmail) {
          // Re-validate format just in case it changed between debounce start and fire
          if (RegExp(
            r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
          ).hasMatch(emailAtDebounceTime)) {
            _log(
              "onEmailChanged (debounce): Triggering check for '$emailAtDebounceTime'.",
            );
            _checkEmailExistsDebounced(emailAtDebounceTime);
          } else {
            _log(
              "onEmailChanged (debounce): Email format became invalid ('$emailAtDebounceTime') before check trigger. Aborting.",
            );
            // Optionally reset status here if needed, e.g., set to idle
            if (mounted) {
              setState(() {
                _emailCheckStatus = EmailCheckStatus.idle;
                _welcomeMessage = 'Invalid email format.';
                _lastCheckedEmail =
                    null; // Clear last checked as it's invalid now
              });
            }
          }
        } else {
          _log(
            "onEmailChanged (debounce): Skipping check trigger. Conditions changed: [Mounted:$mounted, NotChecking:${!_isCheckInProgress}, EmailSame:${emailAtDebounceTime == trimmedEmail}]",
          );
        }
      });
    } else {
      _log(
        "onEmailChanged: Conditions to start debounce NOT met. [Format:$isFormatValid, New:$isNewEmailToCheck, NotChecking:${!_isCheckInProgress}]",
      );
      // If format became invalid *after* a successful check, reset the status.
      if (!isFormatValid &&
          (_emailCheckStatus == EmailCheckStatus.exists ||
              _emailCheckStatus == EmailCheckStatus.notFound)) {
        _log(
          "onEmailChanged: Email format became invalid ('$trimmedEmail') after a check result was shown. Resetting status.",
        );
        if (mounted) {
          setState(() {
            _emailCheckStatus = EmailCheckStatus.idle; // Go back to idle
            _welcomeMessage = 'Invalid email format.';
            _lastCheckedEmail =
                null; // Clear last checked email because current input is invalid
            _passwordController
                .clear(); // Clear password if email becomes invalid
            _isPasswordVisible = false;
          });
        }
      }
    }
  }

  Future<void> _checkEmailExistsDebounced(String email) async {
    // Double-check conditions at the start of the async operation
    if (_isCheckInProgress || _isSubmitting) {
      _log(
        "checkEmailExistsDebounced: Aborted start for '$email'. Already in progress (Checking=$_isCheckInProgress, Submitting=$_isSubmitting)",
      );
      return;
    }
    // Ensure the email hasn't changed *again* since the debounce timer fired
    if (!mounted || _emailController.text.trim() != email) {
      _log(
        "checkEmailExistsDebounced: Aborted start for '$email'. Component unmounted or email changed again.",
      );
      return;
    }

    _log(
      "checkEmailExistsDebounced: Starting check for '$email'. Setting state to checking...",
    );
    // Set state SYNCHRONOUSLY before the await call
    setState(() {
      _emailCheckStatus = EmailCheckStatus.checking;
      _isCheckInProgress = true;
      _welcomeMessage = ''; // Clear previous messages
      _authSubmitStatusMessage = '';
      // Do NOT clear _lastCheckedEmail here. Keep it until we have a new result.
      _log(
        "checkEmailExistsDebounced: setState (sync) completed -> Status=checking, Checking=true",
      );
    });

    // --- Firebase Call ---
    EmailCheckStatus finalStatus = EmailCheckStatus.error; // Default to error
    String finalMessage = 'Error during email check.';
    List<String> methods = [];

    try {
      _log(
        "checkEmailExistsDebounced: Calling Firebase fetchSignInMethodsForEmail('$email')...",
      );
      methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      // **** CRITICAL LOGGING ****
      _log(
        "checkEmailExistsDebounced: Firebase returned methods for '$email': $methods (Count: ${methods.length})",
      );

      // Determine status based on the result
      finalStatus =
          methods.isNotEmpty
              ? EmailCheckStatus.exists
              : EmailCheckStatus.notFound;
      finalMessage =
          finalStatus == EmailCheckStatus.exists
              ? '👋 Welcome back!'
              : '✨ New user? Welcome to Carbon Shodhak!'; // Adjusted message for clarity
      _log(
        "checkEmailExistsDebounced: Check successful for '$email'. Determined Status: $finalStatus",
      );
    } on FirebaseAuthException catch (e) {
      _log(
        "checkEmailExistsDebounced: Firebase error for '$email'. Code: ${e.code}, Message: ${e.message}",
      );
      finalStatus = EmailCheckStatus.error;
      // Provide a slightly more informative error message if possible
      finalMessage = 'Error checking email: ${e.code}. Please try again.';
      // Consider specific handling for network errors, etc.
      if (e.code == 'invalid-email') {
        finalMessage = 'The email format is invalid.';
      } else if (e.code == 'network-request-failed') {
        finalMessage = 'Network error. Check connection.';
      }
    } catch (e, s) {
      // Catch generic errors and stack trace
      _log(
        "checkEmailExistsDebounced: Unexpected error for '$email': $e\nStackTrace: $s",
      );
      finalStatus = EmailCheckStatus.error;
      finalMessage = 'An unexpected error occurred during email check.';
    } finally {
      _log(
        "checkEmailExistsDebounced (finally): Processing check result for '$email'. Determined final status: $finalStatus",
      );
      if (!mounted) {
        _log(
          "checkEmailExistsDebounced (finally): Component unmounted for '$email' before final state update. Aborting setState.",
        );
        // Ensure flag is reset even if unmounted to prevent potential future blocks
        _isCheckInProgress = false;
        return;
      }

      // IMPORTANT: Update _lastCheckedEmail ONLY if the check concluded without error (exists or notFound)
      final String? emailThatWasChecked =
          (finalStatus == EmailCheckStatus.exists ||
                  finalStatus == EmailCheckStatus.notFound)
              ? email
              : _lastCheckedEmail; // Keep the old value if check errored

      _log(
        "checkEmailExistsDebounced (finally): Preparing final setState for '$email'. New Status=$finalStatus, New Message='$finalMessage', New LastChecked=$emailThatWasChecked",
      );

      // Final state update
      setState(() {
        _emailCheckStatus = finalStatus;
        _welcomeMessage = finalMessage;
        _isCheckInProgress = false; // Mark check as finished
        _lastCheckedEmail =
            emailThatWasChecked; // Update based on success/failure

        // Clear password field ONLY if the result indicates a NEW user (notFound)
        // or if an error occurred (safer to clear). Keep it if user exists.
        if (finalStatus == EmailCheckStatus.notFound ||
            finalStatus == EmailCheckStatus.error) {
          _passwordController.clear();
          _isPasswordVisible = false; // Hide if cleared
        }

        // **** CRITICAL LOGGING ****
        _log(
          "checkEmailExistsDebounced (finally): setState completed. Current State: Status=$_emailCheckStatus, Checking=$_isCheckInProgress, LastChecked=$_lastCheckedEmail, WelcomeMsg='$_welcomeMessage'",
        );
      });
    }
  }

  Future<void> _submitAuthForm() async {
    _log("submitAuthForm: Attempting submission...");
    final form = _formKey.currentState;
    if (form == null) {
      _log("submitAuthForm: Form key is null!");
      return;
    }

    // Capture the state *before* validation might trigger rebuilds
    final EmailCheckStatus statusBeforeValidation = _emailCheckStatus;
    final String emailBeforeValidation = _emailController.text.trim();
    _log(
      "submitAuthForm: State before validation: Status=$statusBeforeValidation for Email='$emailBeforeValidation'",
    );

    // Validate the form
    if (!form.validate()) {
      _log("submitAuthForm: Form validation failed.");
      // Clear previous submission errors if validation fails now
      if (_authSubmitStatusMessage.isNotEmpty) {
        if (mounted) setState(() => _authSubmitStatusMessage = '');
      }
      return;
    }
    _log("submitAuthForm: Form validation PASSED.");

    // **CRITICAL CHECK**: Re-confirm the status *after* validation, as the check might have finished
    // during validation or user interaction. Use the status derived from the LATEST successful check.
    // This uses the current state variable which *should* have been updated by _checkEmailExistsDebounced.
    final EmailCheckStatus currentEmailStatus = _emailCheckStatus;
    _log(
      "submitAuthForm: Captured status post-validation: $currentEmailStatus",
    );

    // Ensure we only proceed if the email check has successfully completed
    // (either exists or notFound). Don't submit if idle, checking, or error.
    if (currentEmailStatus != EmailCheckStatus.exists &&
        currentEmailStatus != EmailCheckStatus.notFound) {
      _log(
        "submitAuthForm: Submission blocked. Email status is $currentEmailStatus (Requires exists or notFound).",
      );
      if (mounted) {
        setState(() {
          _authSubmitStatusMessage =
              "Cannot submit. Please ensure email is checked first.";
        });
      }
      return;
    }

    // Prevent double submission
    if (_isSubmitting) {
      _log("submitAuthForm: Submission blocked. Already submitting.");
      return;
    }

    _log("submitAuthForm: Proceeding with submission...");
    if (!mounted) {
      _log("submitAuthForm: Aborted submission. Component unmounted.");
      return;
    }

    // Set submitting state
    setState(() {
      _isSubmitting = true;
      _authSubmitStatusMessage = ''; // Clear previous errors
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Determine action based on the *current* email status
    final bool attemptSignIn = (currentEmailStatus == EmailCheckStatus.exists);
    _log(
      "submitAuthForm: Action: ${attemptSignIn ? 'SIGN IN' : 'SIGN UP'} for email '$email'",
    );

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
          "submitAuthForm: Calling Firebase createUserWithEmailAndPassword...",
        );
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        _log("submitAuthForm: Sign Up SUCCESSFUL.");
      }

      // Check if component is still mounted after async operation
      if (!mounted) {
        _log(
          "submitAuthForm: Component unmounted after successful Firebase call. Aborting navigation.",
        );
        return; // Don't proceed if unmounted
      }

      // Check if user object exists
      if (userCredential.user != null) {
        _log("submitAuthForm: User object retrieved. Navigating...");
        _navigateToCarbonDataScreen();
      } else {
        // This case is less common but possible
        _log(
          "submitAuthForm: Auth successful but user object is null. Displaying message.",
        );
        setState(() {
          _authSubmitStatusMessage =
              "Authentication successful, but failed to retrieve user data.";
          _isSubmitting = false; // Reset submitting flag
        });
      }
    } on FirebaseAuthException catch (e) {
      _log(
        "submitAuthForm: Firebase Error during submission. Code: ${e.code}, Message: ${e.message}",
      );
      if (!mounted) {
        _log(
          "submitAuthForm: Component unmounted after Firebase error. Aborting state update.",
        );
        return; // Don't update state if unmounted
      }

      final errorMessage = _getAuthErrorMessage(e.code);
      final statusBeforeErrorHandling =
          _emailCheckStatus; // For logging comparison

      // --- **Error Correction Logic** ---
      // If Firebase returns an error that contradicts our current state, correct the state.
      EmailCheckStatus correctedStatus = statusBeforeErrorHandling;
      String correctedWelcomeMessage = _welcomeMessage;
      String? correctedLastChecked = _lastCheckedEmail;
      bool stateCorrected = false;

      if (attemptSignIn && _isUserNotFoundError(e.code)) {
        // Tried to Sign In, but user doesn't exist -> Should be Sign Up
        _log(
          "submitAuthForm: Correcting state. Sign In failed (user not found), changing status to notFound.",
        );
        correctedStatus = EmailCheckStatus.notFound;
        correctedWelcomeMessage = '✨ Email not found. Please Sign Up.';
        // Clear last checked email as the sign-in assumption was wrong
        // Or maybe keep it as 'email'? Let's clear it to force re-check if needed.
        correctedLastChecked = null;
        stateCorrected = true;
      } else if (!attemptSignIn && _isEmailInUseError(e.code)) {
        // Tried to Sign Up, but email already exists -> Should be Sign In
        _log(
          "submitAuthForm: Correcting state. Sign Up failed (email in use), changing status to exists.",
        );
        correctedStatus = EmailCheckStatus.exists;
        correctedWelcomeMessage =
            '👋 Email already registered. Please Sign In.';
        // Set last checked email because we now know it exists
        correctedLastChecked = email;
        stateCorrected = true;
      }

      setState(() {
        _authSubmitStatusMessage = errorMessage;
        if (stateCorrected) {
          _emailCheckStatus = correctedStatus;
          _welcomeMessage = correctedWelcomeMessage;
          _lastCheckedEmail = correctedLastChecked;
          _log(
            "submitAuthForm: State corrected after error. Before=$statusBeforeErrorHandling, After=$_emailCheckStatus, LastChecked=$_lastCheckedEmail",
          );
        }
        _isSubmitting = false; // Reset submitting flag
      });
    } catch (e, s) {
      _log(
        "submitAuthForm: Unexpected error during submission: $e\nStackTrace: $s",
      );
      if (!mounted) {
        _log(
          "submitAuthForm: Component unmounted after unexpected error. Aborting state update.",
        );
        return;
      }
      setState(() {
        _authSubmitStatusMessage =
            'An unexpected error occurred during submission.';
        _isSubmitting = false; // Reset submitting flag
      });
    } finally {
      // Ensure submitting flag is always reset if still true and mounted
      if (mounted && _isSubmitting) {
        _log("submitAuthForm (finally): Resetting _isSubmitting flag.");
        setState(() => _isSubmitting = false);
      }
    }
  }

  // --- Error Message & Helpers --- (No changes needed from original)
  String _getAuthErrorMessage(String errorCode) {
    _log("getAuthErrorMessage: Formatting error for code: $errorCode");
    // Using lowercase for broader matching
    switch (errorCode.toLowerCase()) {
      case 'user-not-found':
      case 'auth/user-not-found':
        return 'No user found with this email. Please check the email or sign up.';
      case 'wrong-password':
      case 'auth/wrong-password':
        return 'Incorrect password. Please try again.';
      // Firebase might return invalid-credential for both wrong email/password during sign-in
      case 'invalid-credential':
      case 'auth/invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
      case 'auth/email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'weak-password':
      case 'auth/weak-password':
        return 'Password is too weak (must be at least 6 characters).';
      case 'invalid-email':
      case 'auth/invalid-email':
        return 'The email address format is not valid.';
      case 'network-request-failed':
      case 'auth/network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
      case 'auth/too-many-requests':
        return 'Access temporarily disabled due to too many attempts. Please try again later.';
      case 'user-disabled':
      case 'auth/user-disabled':
        return 'This user account has been disabled.';
      default:
        _log("getAuthErrorMessage: Unhandled error code: $errorCode");
        return 'An authentication error occurred. ($errorCode)';
    }
  }

  bool _isUserNotFoundError(String errorCode) {
    final code = errorCode.toLowerCase();
    // Include invalid-credential as it's often used for user not found during sign-in
    return code == 'user-not-found' ||
        code == 'auth/user-not-found' ||
        code == 'invalid-credential' ||
        code == 'auth/invalid-credential';
  }

  bool _isEmailInUseError(String errorCode) {
    final code = errorCode.toLowerCase();
    return code == 'email-already-in-use' ||
        code == 'auth/email-already-in-use';
  }

  // --- Navigation --- (No changes needed)
  void _navigateToCarbonDataScreen() {
    if (!mounted) {
      _log("navigateToCarbonDataScreen: Aborted. Component unmounted.");
      return;
    }
    _log("Navigating to CarbonDataScreen...");
    // Replace the current route stack with the new screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const CarbonDataScreen(),
      ), // Ensure CarbonDataScreen is correctly imported/defined
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Capture state at the beginning of the build method for consistency within this build pass
    final EmailCheckStatus currentStatus = _emailCheckStatus;
    final bool currentlyChecking = _isCheckInProgress;
    final bool currentlySubmitting = _isSubmitting;

    // **** CRITICAL LOGGING: Log state every time build runs ****
    _log(
      "build: UI Rebuilding. Status=$currentStatus, Checking=$currentlyChecking, Submitting=$currentlySubmitting, LastChecked=$_lastCheckedEmail, WelcomeMsg='$_welcomeMessage', AuthMsg='$_authSubmitStatusMessage'",
    );

    // Determine UI visibility and enabled states based on captured state
    final bool showSubmitWidgets =
        (currentStatus == EmailCheckStatus.exists ||
            currentStatus == EmailCheckStatus.notFound);
    final bool enableFields =
        !currentlyChecking &&
        !currentlySubmitting; // Email field enabled when not checking AND not submitting
    final bool enableSubmitButton =
        showSubmitWidgets &&
        !currentlySubmitting; // Submit button enabled only when status is known AND not submitting

    // Determine button text defensively based on the status that allows submission
    String buttonText;
    if (currentStatus == EmailCheckStatus.exists) {
      buttonText = 'Sign In';
    } else if (currentStatus == EmailCheckStatus.notFound) {
      buttonText = 'Sign Up';
    } else {
      // Fallback text for states where the button *shouldn't* be active anyway
      // Defaulting to 'Sign Up' might be less confusing than an empty/weird state
      buttonText = 'Sign Up';
      _log(
        "build: Button text set to fallback '$buttonText' because status is $currentStatus",
      );
    }
    _log(
      "build: Determined Button Text = '$buttonText' based on Status=$currentStatus. Submit Enabled=$enableSubmitButton",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon शोधक Authentication'),
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary, // Example styling
      ),
      body: Center(
        child: ConstrainedBox(
          // Limit width for better appearance on large screens
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // --- Welcome Message Area ---
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                    ), // Ensure space even when empty
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child:
                        _welcomeMessage.isNotEmpty
                            ? Text(
                              _welcomeMessage,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _getWelcomeMessageColor(
                                  currentStatus,
                                ), // Dynamic color
                              ),
                              textAlign: TextAlign.center,
                            )
                            : const SizedBox(
                              height: 1,
                            ), // Minimal space holder if no message
                  ),

                  // --- Email Field ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    enabled: enableFields, // Use combined enable flag
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                      // Show loading indicator only when actively checking
                      suffixIcon:
                          currentlyChecking
                              ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                              : null, // No icon otherwise
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Please enter your email.';
                      if (!RegExp(
                        r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
                      ).hasMatch(v)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // --- Password & Submit Area (Animated) ---
                  // Use AnimatedOpacity + Visibility to smoothly show/hide
                  AnimatedOpacity(
                    opacity: showSubmitWidgets ? 1.0 : 0.0,
                    duration: const Duration(
                      milliseconds: 400,
                    ), // Slightly longer duration
                    child: Visibility(
                      // Use maintainState=true to keep the state (like password) even when hidden
                      visible: showSubmitWidgets,
                      maintainState: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- Password Field ---
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            // Only enable if not submitting (even if fields above are disabled during check)
                            enabled: !currentlySubmitting,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                // Disable toggle button while submitting
                                onPressed:
                                    currentlySubmitting
                                        ? null
                                        : () {
                                          // Ensure mounted check before setState
                                          if (mounted) {
                                            setState(
                                              () =>
                                                  _isPasswordVisible =
                                                      !_isPasswordVisible,
                                            );
                                          }
                                        },
                              ),
                            ),
                            validator: (value) {
                              // Only validate password if the submit widgets are supposed to be shown
                              if (showSubmitWidgets) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty)
                                  return 'Please enter your password.';
                                if (v.length < 6)
                                  return 'Password must be at least 6 characters.';
                              }
                              return null; // No error if widgets aren't shown
                            },
                            // Allow submitting from keyboard action
                            onFieldSubmitted: (_) {
                              if (enableSubmitButton) _submitAuthForm();
                            },
                          ),
                          const SizedBox(height: 25),

                          // --- Submit Button ---
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              // Consider adding backgroundColor based on theme
                              // backgroundColor: Theme.of(context).colorScheme.primary,
                              // foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            // Use the combined enable flag
                            onPressed:
                                enableSubmitButton ? _submitAuthForm : null,
                            child:
                                currentlySubmitting
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ), // Assuming button bg is dark
                                      ),
                                    )
                                    : Text(
                                      buttonText,
                                    ), // Use the determined button text
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Authentication Error Message Area ---
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                    ), // Ensure space
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 20.0),
                    child:
                        _authSubmitStatusMessage.isNotEmpty
                            ? Text(
                              _authSubmitStatusMessage,
                              style: const TextStyle(
                                color:
                                    Colors
                                        .redAccent, // Use a distinct error color
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                            : const SizedBox(height: 1), // Minimal space holder
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for welcome message color (No changes needed)
  Color _getWelcomeMessageColor(EmailCheckStatus status) {
    switch (status) {
      case EmailCheckStatus.exists:
        return Theme.of(
          context,
        ).colorScheme.primary; // Theme primary for existing
      case EmailCheckStatus.notFound:
        return Colors.green.shade700; // Green for new user welcome
      case EmailCheckStatus.error:
        return Theme.of(context).colorScheme.error; // Theme error for errors
      case EmailCheckStatus.checking:
        return Theme.of(context).textTheme.bodySmall?.color ??
            Colors.grey; // Muted while checking
      case EmailCheckStatus.idle:
      default:
        return Theme.of(context).textTheme.bodyLarge?.color ??
            Colors.black; // Default text color
    }
  }
}
