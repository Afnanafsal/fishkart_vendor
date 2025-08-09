import 'package:fishkart_vendor/components/async_progress_dialog.dart';
import 'package:fishkart_vendor/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:fishkart_vendor/exceptions/firebaseauth/signin_exceptions.dart';
import 'package:fishkart_vendor/screens/forgot_password/forgot_password_screen.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/providers/user_providers.dart'
    as user_providers;
import 'package:logger/logger.dart';

import '../../../components/custom_suffix_icon.dart';
import '../../../components/default_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../size_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignInForm extends ConsumerStatefulWidget {
  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formkey = GlobalKey<FormState>();

  final TextEditingController emailFieldController = TextEditingController();
  final TextEditingController passwordFieldController = TextEditingController();

  @override
  void dispose() {
    emailFieldController.dispose();
    passwordFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(user_providers.signInFormProvider);
    bool buttonDisabled = formState.isLoading;

    return Form(
      key: _formkey,
      child: Column(
        children: [
          buildEmailFormField(),
          SizedBox(height: 30.h),
          buildPasswordFormField(),
          SizedBox(height: 30.h),
          buildForgotPasswordWidget(context),
          SizedBox(height: 30.h),
          DefaultButton(
            text: "Sign in",
            press: buttonDisabled
                ? null
                : () async {
                    ref
                        .read(user_providers.signInFormProvider.notifier)
                        .setLoading(true);
                    await signInButtonCallback();
                  },
          ),
        ],
      ),
    );
  }

  Widget buildForgotPasswordWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
            );
          },
          child: Text(
            "Forgot Password",
            style: TextStyle(
              decoration: TextDecoration.underline,
              fontSize: 15.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordFormField() {
    return TextFormField(
      controller: passwordFieldController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Enter your password",
        labelText: "Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black, width: 2.w),
        ),
      ),
      validator: (value) {
        if (passwordFieldController.text.isEmpty) {
          return kPassNullError;
        } else if (passwordFieldController.text.length < 8) {
          return kShortPassError;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildEmailFormField() {
    return TextFormField(
      controller: emailFieldController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "Enter your email",
        labelText: "Email",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black, width: 2.w),
        ),
      ),
      validator: (value) {
        if (emailFieldController.text.isEmpty) {
          return kEmailNullError;
        } else if (!emailValidatorRegExp.hasMatch(emailFieldController.text)) {
          return kInvalidEmailError;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Future<void> signInButtonCallback() async {
    if (_formkey.currentState?.validate() ?? false) {
      _formkey.currentState?.save();
      ref.read(user_providers.signInFormProvider.notifier).setLoading(true);
      final AuthentificationService authService = AuthentificationService();
      bool signInStatus = false;
      String snackbarMessage = '';
      try {
        final signInFuture = authService.signIn(
          email: emailFieldController.text.trim(),
          password: passwordFieldController.text.trim(),
        );
        signInStatus = await showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              signInFuture,
              message: Text("Signing in to account"),
              onError: (e) {
                if (e is MessagedFirebaseAuthException) {
                  snackbarMessage = e.message;
                } else {
                  snackbarMessage = "Something went wrong. Please try again.";
                }
              },
            );
          },
        );
        if (signInStatus == true) {
          snackbarMessage = "Signed In Successfully";
        } else {
          if (snackbarMessage.isEmpty) {
            snackbarMessage = "Something went wrong. Please try again.";
          }
        }
      } on MessagedFirebaseAuthException catch (e) {
        snackbarMessage = e.message;
      } catch (e) {
        snackbarMessage = "Something went wrong. Please try again.";
      } finally {
        ref.read(user_providers.signInFormProvider.notifier).setLoading(false);
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
  }
}
