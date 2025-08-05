import 'package:url_launcher/url_launcher.dart';
import 'package:fishkart_vendor/constants.dart';
import 'package:flutter/material.dart';
import '../../../size_config.dart';
import '../../../components/no_account_text.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart_vendor/providers/user_providers.dart'
    as user_providers;
import 'package:fishkart_vendor/screens/sign_up/sign_up_screen.dart';
import 'package:fishkart_vendor/screens/forgot_password/forgot_password_screen.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:fishkart_vendor/screens/home/home_screen.dart';
import 'dart:async';

Timer? _emailCheckTimer;
bool _showingVerificationDialog = false;

Future<void> _checkEmailVerified(BuildContext context) async {
  final user = AuthentificationService().currentUser;
  await user.reload();
  if (!user.emailVerified && !_showingVerificationDialog) {
    _showingVerificationDialog = true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verify Your Email'),
        content: Text(
          'A verification link has been sent to your email address. Please verify your email before logging in. If you do not see the email, check your spam folder.',
        ),
        actions: [
          TextButton(
            child: Text('Open Mail'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              _showingVerificationDialog = false;
              const url = 'mailto:';
              try {
                await launchUrl(Uri.parse(url));
              } catch (_) {}
            },
          ),
        ],
      ),
    ).then((_) {
      _showingVerificationDialog = false;
    });
  }
}

void _startEmailVerificationCheck(BuildContext context) {
  _emailCheckTimer?.cancel();
  _emailCheckTimer = Timer.periodic(Duration(seconds: 10), (_) {
    _checkEmailVerified(context);
  });
}

void _stopEmailVerificationCheck() {
  _emailCheckTimer?.cancel();
  _emailCheckTimer = null;
}

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Center(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: SizeConfig.screenHeight * 0.05),
              // fishkart_vendor logo/text (uses 'Shadows Into Light Two' for branding, main font is 'Poppins')
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Shadows Into Light Two',
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Fish',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Kart',
                      style: TextStyle(color: Color(0xFF29465B)),
                    ),
                    WidgetSpan(child: SizedBox(width: 8)),
                    TextSpan(
                      text: 'vendor',
                      style: TextStyle(color: Color.fromARGB(255, 249, 172, 7)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.screenHeight * 0.035),
              // Card with form and social login
              Container(
                width: 340,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _SignInCardContent(),
              ),
              SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInCardContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SignInCardContent> createState() => _SignInCardContentState();
}

class _SignInCardContentState extends ConsumerState<_SignInCardContent> {
  bool keepLoggedIn = true;
  bool passwordVisible = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> handleLogin() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter email and password")),
        );
        return;
      }
      String snackbarMessage = '';
      bool signInStatus = false;
      try {
        final authService = AuthentificationService();
        signInStatus = await authService.signIn(
          email: email,
          password: password,
        );
        snackbarMessage = "Signed In Successfully";
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (signInStatus && context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } on MessagedFirebaseAuthException catch (e) {
        if (e.runtimeType.toString().contains(
          'FirebaseSignInAuthUserNotVerifiedException',
        )) {
          try {
            final authService = AuthentificationService();
            await authService.sendVerificationEmailToCurrentUser();
          } catch (_) {}
          _startEmailVerificationCheck(context);
          snackbarMessage =
              "Please verify your email before logging in. A verification link has been sent to your email.";
          @override
          void dispose() {
            _stopEmailVerificationCheck();
            super.dispose();
          }
        } else if (e.runtimeType.toString().contains(
          'FirebaseSignInAuthWrongPasswordException',
        )) {
          snackbarMessage = "Incorrect password. Please try again.";
        } else if (e.runtimeType.toString().contains(
          'FirebaseSignInAuthUserNotFoundException',
        )) {
          snackbarMessage = "No account found for this email.";
        } else if (e.runtimeType.toString().contains(
          'FirebaseSignInAuthInvalidEmailException',
        )) {
          snackbarMessage = "Invalid email address.";
        } else if (e.runtimeType.toString().contains(
          'FirebaseSignInAuthUserDisabledException',
        )) {
          snackbarMessage = "This account has been disabled.";
        } else if (e.runtimeType.toString().contains(
          'FirebaseTooManyRequestsException',
        )) {
          snackbarMessage = "Too many requests. Please try again later.";
        } else {
          snackbarMessage = e.message;
        }
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        snackbarMessage = "An unexpected error occurred. Please try again.";
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
      if (!signInStatus) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "youremail@gmail.com",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
        SizedBox(height: 18),
        Text(
          "Password",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: !passwordVisible,
          decoration: InputDecoration(
            hintText: "************",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  passwordVisible = !passwordVisible;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: keepLoggedIn,
              activeColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                setState(() {
                  keepLoggedIn = val ?? true;
                });
              },
            ),
            Text(
              "Keep me logged in",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => SignUpScreen()));
              },
              child: Text(
                "Sign Up",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            onPressed: handleLogin,
            child: Text(
              "Login",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Or",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: 16),
        // Social login buttons
        Column(
          children: [
            SizedBox(height: 12),
            _SocialButton(
              iconAsset: 'assets/icons/google-icon.png',
              text: 'Continue with Google',
              onPressed: () async {
                try {
                  final authService = AuthentificationService();
                  final result = await authService.signInWithGoogle();
                  if (result == true) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else if (result == 'signup') {
                    // Always disconnect to force account picker and get fresh data
                    final googleSignIn = GoogleSignIn();
                    await googleSignIn.disconnect();
                    final GoogleSignInAccount? googleUser = await googleSignIn
                        .signIn();
                    if (googleUser != null) {
                      final name = googleUser.displayName ?? '';
                      final email = googleUser.email;
                      final signUpFormNotifier = ref.read(
                        user_providers.signUpFormDataProvider.notifier,
                      );
                      signUpFormNotifier.updateDisplayName(name);
                      signUpFormNotifier.updateEmail(email);
                      Navigator.of(context).pushReplacementNamed('/sign_up');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Google sign-in cancelled")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Google sign-in failed")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Google sign-in error: $e")),
                  );
                }
              },
            ),
            SizedBox(height: 12),
            _SocialButton(
              iconAsset: 'assets/icons/facebook.png',
              text: 'Continue with Facebook',
              onPressed: () async {
                try {
                  final authService = AuthentificationService();
                  final result = await authService.signInWithFacebook();
                  if (result) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Facebook sign-in failed")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Facebook sign-in error: $e")),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

// Social login button widget
class _SocialButton extends StatelessWidget {
  final String? iconAsset;
  final String text;
  final VoidCallback onPressed;
  const _SocialButton({
    this.iconAsset,
    required this.text,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (iconAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Image.asset(iconAsset!, fit: BoxFit.contain),
                ),
              ),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
