import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/components/async_progress_dialog.dart';
import 'package:fishkart_vendor/components/custom_suffix_icon.dart';
import 'package:fishkart_vendor/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../../../constants.dart';
import '../../home/home_screen.dart';
import 'package:fishkart_vendor/providers/user_providers.dart'
    as user_providers;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUpForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailFieldController = TextEditingController();
  final TextEditingController passwordFieldController = TextEditingController();
  final TextEditingController confirmPasswordFieldController =
      TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController areaLocationController = TextEditingController();
  @override
  void dispose() {
    emailFieldController.dispose();
    passwordFieldController.dispose();
    confirmPasswordFieldController.dispose();
    displayNameController.dispose();
    phoneNumberController.dispose();
    areaLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(user_providers.signUpFormProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Name",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          buildDisplayNameFormField(),
          SizedBox(height: 8.h),
          Text(
            "Phone number",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          buildPhoneNumberFormField(),
          SizedBox(height: 8.h),
          Text(
            "Area Location",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          buildAreaLocationFormField(),
          SizedBox(height: 8.h),
          Text(
            "Email",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          buildEmailFormField(),
          SizedBox(height: 8.h),
          Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          buildPasswordFormField(),
          SizedBox(height: 8.h),
          Text(
            "Confirm Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          buildConfirmPasswordFormField(),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 18.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: formState.isLoading
                  ? null
                  : () async {
                      await signUpButtonCallback();
                    },
              child: Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAreaLocationFormField() {
    return TextFormField(
      controller: areaLocationController,
      decoration: InputDecoration(
        hintText: "your_area_location",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/add_location.svg"),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 2.w),
        ),
      ),
      onChanged: (value) {
        ref
            .read(user_providers.signUpFormDataProvider.notifier)
            .updateAreaLocation(value);
      },
      validator: (value) {
        if (areaLocationController.text.isEmpty) {
          return "Please enter your area location";
        } else if (areaLocationController.text.length < 2) {
          return "Area location must be at least 2 characters";
        } else if (areaLocationController.text.length > 50) {
          return "Area location must be less than 50 characters";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildDisplayNameFormField() {
    return TextFormField(
      controller: displayNameController,
      decoration: InputDecoration(
        hintText: "your_name",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/User.svg"),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 2.w),
        ),
      ),
      onChanged: (value) {
        ref
            .read(user_providers.signUpFormDataProvider.notifier)
            .updateDisplayName(value);
      },
      validator: (value) {
        if (displayNameController.text.isEmpty) {
          return "Please enter your display name";
        } else if (displayNameController.text.length < 2) {
          return "Display name must be at least 2 characters";
        } else if (displayNameController.text.length > 30) {
          return "Display name must be less than 30 characters";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildPhoneNumberFormField() {
    return TextFormField(
      controller: phoneNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: "your_phone_number",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Phone.svg"),
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 2.w),
        ),
      ),
      onChanged: (value) {
        ref
            .read(user_providers.signUpFormDataProvider.notifier)
            .updatePhoneNumber(value);
      },
      validator: (value) {
        if (phoneNumberController.text.isEmpty) {
          return "Please enter your phone number";
        } else if (phoneNumberController.text.length < 10) {
          return "Phone number must be at least 10 digits";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildConfirmPasswordFormField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: confirmPasswordFieldController,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            hintText: "************",
            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 16.w,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black, width: 1.5.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black, width: 2.w),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey,
                size: 22.sp,
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
          ),
          onChanged: (value) {
            ref
                .read(user_providers.signUpFormDataProvider.notifier)
                .updateConfirmPassword(value);
          },
          validator: (value) {
            if (confirmPasswordFieldController.text.isEmpty) {
              return kPassNullError;
            } else if (confirmPasswordFieldController.text !=
                passwordFieldController.text) {
              return kMatchPassError;
            } else if (confirmPasswordFieldController.text.length < 8) {
              return kShortPassError;
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        );
      },
    );
  }

  Widget buildEmailFormField() {
    return TextFormField(
      controller: emailFieldController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "youremail@gmail.com",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black, width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
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

  Widget buildPasswordFormField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: passwordFieldController,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            hintText: "************",
            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 16.w,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black, width: 1.5.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black, width: 2.w),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
                size: 22.sp,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
          onChanged: (value) {
            ref
                .read(user_providers.signUpFormDataProvider.notifier)
                .updatePassword(value);
          },
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
      },
    );
  }

  Future<void> signUpButtonCallback() async {
    if (ref.read(user_providers.signUpFormProvider).isLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
      final authService = ref.read(user_providers.authServiceProvider);
      final formNotifier = ref.read(user_providers.signUpFormProvider.notifier);
      formNotifier.setLoading(true);
      String snackbarMessage = '';
      try {
        // Check if email already exists
        final email = emailFieldController.text.trim();
        final existing = await FirebaseFirestore.instance
            .collection('vendors')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          snackbarMessage = "Email already exists. Please use another email.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackbarMessage),
              backgroundColor: Colors.red,
            ),
          );
          formNotifier.setLoading(false);
          return;
        }
        final signUpFuture = authService
            .signUpWithCompleteProfile(
              email: email,
              password: passwordFieldController.text,
              displayName: displayNameController.text,
              phoneNumber: phoneNumberController.text,
              areaLocation: areaLocationController.text,
            )
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw Exception("Timeout"),
            );
        final result = await showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              signUpFuture,
              message: Text("Creating new account"),
            );
          },
        );
        final signUpStatus = result == true;
        if (signUpStatus) {
          final user = authService.currentUser;
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .set({
                'displayName': displayNameController.text,
                'email': emailFieldController.text,
                'phoneNumber': phoneNumberController.text,
                'areaLocation': areaLocationController.text,
                'userType': 'vendor',
              });
          snackbarMessage = "Account created successfully!";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackbarMessage),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        } else {
          snackbarMessage = "Can't register due to unknown reason";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackbarMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on MessagedFirebaseAuthException catch (e) {
        snackbarMessage = e.message;
        if (snackbarMessage.contains("customer")) {
          snackbarMessage =
              "Signup failed. Please check your details and try again.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackbarMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        snackbarMessage = e.toString();
        if (snackbarMessage.contains("customer")) {
          snackbarMessage =
              "Signup failed. Please check your details and try again.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackbarMessage), backgroundColor: Colors.red),
        );
      } finally {
        formNotifier.setLoading(false);
        Logger().i(snackbarMessage);
      }
    }
  }

  // Helper function to add product with vendorId and areaLocation
  // Call this when vendor adds a product
  Future<void> addProductForVendor({
    required String productName,
    required double productPrice,
    required String vendorId,
    required String areaLocation,
  }) async {
    // import 'package:cloud_firestore/cloud_firestore.dart';
    await FirebaseFirestore.instance.collection('products').add({
      'name': productName,
      'price': productPrice,
      'vendorId': vendorId,
      'areaLocation': areaLocation,
      // add other product fields as needed
    });
  }

  // To filter products by location in customer app:
  // FirebaseFirestore.instance.collection('products').where('areaLocation', isEqualTo: userAreaLocation).get();
}
