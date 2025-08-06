import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/size_config.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data?['display_name'] ?? data?['name'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F9FC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(24),
          vertical: getProportionateScreenHeight(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello ${name.isNotEmpty ? name : ''}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'View overall statistics of your\nproducts below in the last',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748b),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Color(0xFF1e293b),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/order');
              },
              tooltip: 'Inbox',
            ),
          ],
        ),
      ),
    );
  }
}
