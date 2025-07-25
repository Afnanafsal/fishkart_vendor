import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart_vendor/screens/home/home_screen.dart';
import 'package:fishkart_vendor/screens/sign_in/sign_in_screen.dart';
import 'package:fishkart_vendor/providers/user_providers.dart';

class AuthentificationWrapper extends ConsumerWidget {
  static const String routeName = "/authentification_wrapper";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Check userType in Firestore 'vendors' collection
          return FutureBuilder(
            future: ref
                .read(userDatabaseHelperProvider)
                .firestore
                .collection('vendors')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              final data = snapshot.data?.data();
              final userType = data != null ? data['userType'] : null;
              // If you expect any boolean fields, always use == true for checks
              // Example: final isActive = data != null ? data['isActive'] == true : false;
              if (userType != null && userType == 'vendor') {
                return HomeScreen();
              } else if (data == null || userType == null) {
                // Document not yet created or incomplete, show loading
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'This account is not registered as a vendor. Please sign up as a vendor.',
                        ),
                      ),
                    );
                  }
                });
                return SignInScreen();
              }
            },
          );
        } else {
          return SignInScreen();
        }
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
