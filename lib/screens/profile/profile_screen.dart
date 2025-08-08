import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:hive/hive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils.dart';
import 'edit_profile_screen.dart';
import '../manage_products/category_products_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const _ProfileCard(),
                const SizedBox(height: 32),
                _ProfileMenuItem(
                  icon: const Icon(Icons.person, size: 22, color: Colors.black),
                  title: 'Edit Account',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ProfileMenuItem(
                  icon: const Icon(Icons.location_on, size: 22, color: Colors.black),
                  title: 'Manage Products',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryProductsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ProfileMenuItem(
                  icon: const ImageIcon(AssetImage('assets/icons/signout.png'), color: Colors.black, size: 22),
                  title: 'Sign Out',
                  onTap: () async {
                    final confirmation = await showConfirmationDialog(
                      context,
                      "Confirm Sign out?",
                    );
                    if (confirmation) {
                      await AuthentificationService().signOut();
                      try {
                        final googleSignIn = GoogleSignIn();
                        await googleSignIn.disconnect();
                      } catch (_) {}
                      Future.delayed(const Duration(milliseconds: 300), () {
                        SystemNavigator.pop();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AuthentificationService().currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        Uint8List? chosenImageBytes;
        String? displayPictureUrl;
        String displayName = 'No Name';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();
        if (data != null) {
          displayName = data['display_name'] ?? user.displayName ?? 'No Name';
          final fetched = data['display_picture'] as String?;
          if (fetched != null && fetched.isNotEmpty) {
            if (fetched.startsWith('http')) {
              displayPictureUrl = fetched;
              chosenImageBytes = null;
            } else if (!fetched.startsWith('blob:')) {
              try {
                chosenImageBytes = base64Decode(fetched);
                displayPictureUrl = null;
              } catch (_) {
                chosenImageBytes = null;
                displayPictureUrl = null;
              }
            } else {
              // blob: url, treat as no image
              chosenImageBytes = null;
              displayPictureUrl = null;
            }
          }
        }

        Widget avatar;
        if (chosenImageBytes != null) {
          avatar = CircleAvatar(
            radius: 30,
            backgroundImage: MemoryImage(chosenImageBytes),
          );
        } else if (displayPictureUrl != null && displayPictureUrl.isNotEmpty) {
          avatar = CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(displayPictureUrl),
          );
        } else {
          avatar = const CircleAvatar(radius: 30, backgroundColor: Colors.grey);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hi, there!',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    displayName.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
