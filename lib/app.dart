import 'package:fishkart_vendor/screens/inbox/inbox_page.dart';
import 'package:flutter/material.dart';
import 'package:fishkart_vendor/screens/forgot_password/components/body.dart';
import 'package:fishkart_vendor/screens/edit_address/edit_address_screen.dart';
import 'package:fishkart_vendor/screens/forgot_password/forgot_password_screen.dart';
import 'package:fishkart_vendor/screens/sign_in/sign_in_screen.dart';
import 'package:fishkart_vendor/screens/sign_up/sign_up_screen.dart';
import 'package:fishkart_vendor/screens/splash/splash_screen.dart';
import 'package:fishkart_vendor/wrappers/authentification_wrapper.dart';
import 'package:fishkart_vendor/screens/splash/splash_screen.dart';
import 'package:fishkart_vendor/wrappers/authentification_wrapper.dart';

import 'constants.dart';
import 'theme.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: SplashScreen(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => AuthentificationWrapper(),
        '/sign_in': (context) => SignInScreen(),
        '/sign_up': (context) => SignUpScreen(),
        '/forgot': (context) => ForgotPasswordScreen(),
        '/add_address': (context) => EditAddressScreen(),
        '/inbox': (context) => const InboxPage(),
      },
    );
  }
}
