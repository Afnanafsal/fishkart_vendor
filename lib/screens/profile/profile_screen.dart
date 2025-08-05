import '../manage_products/manage_products_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/screens/sign_in/sign_in_screen.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/services/database/user_database_helper.dart';
import 'package:fishkart_vendor/services/base64_image_service/base64_image_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../constants.dart';
import '../change_location/change_location_screen.dart';
import '../change_display_picture/change_display_picture_screen.dart';
import '../change_email/change_email_screen.dart';
import '../change_password/change_password_screen.dart';
import '../change_phone/change_phone_screen.dart';
// Removed unused import
import '../../utils.dart';
import '../change_display_name/change_display_name_screen.dart';
import 'package:fishkart_vendor/components/async_progress_dialog.dart';

// Removed unused imports
import 'vendor_completed_orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _ProfileHeader(avatarOverlap: true),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                children: [
                  const SizedBox(height: 8),
                  _ProfileActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool avatarOverlap;
  const _ProfileHeader({this.avatarOverlap = false});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserDatabaseHelper().currentUserDataStream,
      builder: (context, userSnap) {
        final user = AuthentificationService().currentUser;
        final displayName = user.displayName ?? 'No Name';
        Widget avatar;
        if (userSnap.connectionState == ConnectionState.waiting) {
          avatar = CircleAvatar(
            radius: 40,
            backgroundColor: kTextColor.withOpacity(0.2),
            child: Icon(Icons.person_rounded, size: 44, color: kTextColor),
          );
        } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          avatar = CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(user.photoURL!),
          );
        } else {
          avatar = CircleAvatar(
            radius: 40,
            backgroundColor: kTextColor.withOpacity(0.2),
            child: Icon(Icons.person_rounded, size: 44, color: kTextColor),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Always show the email from Auth, but name only from Firestore
              AuthentificationService().currentUser.email ?? 'No Email',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileActions extends StatelessWidget {
  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileExpansion(
          icon: Icons.person,
          title: 'Edit Account',
          children: [
            _ProfileActionTile(
              title: 'Change Display Picture',
              icon: Icons.image,
              onTap: () => _push(context, ChangeDisplayPictureScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Display Name',
              icon: Icons.edit,
              onTap: () => _push(context, ChangeDisplayNameScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Phone Number',
              icon: Icons.phone,
              onTap: () => _push(context, ChangePhoneScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Email',
              icon: Icons.email,
              onTap: () => _push(context, ChangeEmailScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Password',
              icon: Icons.lock,
              onTap: () => _push(context, ChangePasswordScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Location',
              icon: Icons.location_on,
              onTap: () => _push(context, ChangeLocationScreen()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.inventory, color: Color(0xFF10b981)),
                title: Text(
                  'Manage Products',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageProductsScreen()),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minLeadingWidth: 32,
                horizontalTitleGap: 12,
                tileColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Removed Manage Addresses
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          ),

        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              color: Colors.red[600],
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.logout),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final confirmation = await showConfirmationDialog(
                      context,
                      "Confirm Sign out ?",
                    );
                    if (confirmation) {
                      await AuthentificationService().signOut();
                      // Disconnect GoogleSignIn to clear cached user data
                      try {
                        final googleSignIn = GoogleSignIn();
                        await googleSignIn.disconnect();
                      } catch (_) {}
                      // Exit the app after sign out
                      Future.delayed(const Duration(milliseconds: 300), () {
                        SystemNavigator.pop();
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Removed unused _handleVerifiedAction method
}

class _ProfileActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ProfileActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF294157)),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 32,
      horizontalTitleGap: 12,
      tileColor: Colors.white,
    );
  }
}

class _ProfileExpansion extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ProfileExpansion({
    required this.title,
    required this.icon,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(cardColor: Colors.white, canvasColor: Colors.white),
        child: ExpansionTile(
          leading: Icon(icon, color: Color(0xFF294157)),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          children: children,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
          initiallyExpanded: true,
        ),
      ),
    );
  }
}
