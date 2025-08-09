import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../size_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 0.10.sh),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Shadows Into Light Two',
                    fontSize: 48.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2.w,
                  ),
                  children: [
                    TextSpan(
                      text: 'Fish',
                      style: TextStyle(
                        color: Color(0xFF29465B),
                        fontSize: 32.sp,
                      ),
                    ),
                    TextSpan(
                      text: 'Kart',
                      style: TextStyle(color: Colors.black, fontSize: 32.sp),
                    ),
                    WidgetSpan(child: SizedBox(width: 8.w)),
                    TextSpan(
                      text: 'vendor',
                      style: TextStyle(color: Color.fromARGB(255, 249, 172, 7)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 0.08.sh),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 32.h,
                    horizontal: 20.w,
                  ),
                  child: ForgotPasswordFormExact(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordFormExact extends StatefulWidget {
  @override
  State<ForgotPasswordFormExact> createState() =>
      _ForgotPasswordFormExactState();
}

class _ForgotPasswordFormExactState extends State<ForgotPasswordFormExact> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent! Check your email.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send reset link.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 16.sp, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'youremail@gmail.com',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16.sp),
            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 12.w,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Colors.blueGrey.shade700,
                width: 1.5.w,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 22.h),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
