import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/size_config.dart';
import 'package:flutter_svg/svg.dart';

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
    return Column(
      children: [
        Container(
          height: 28,
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
        ),
        Container(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          padding: EdgeInsets.only(
            left: getProportionateScreenWidth(16),
            right: getProportionateScreenWidth(16),
            top: 0,
            bottom: getProportionateScreenHeight(16),
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
                        const SizedBox(height: 2),
                        const Text(
                          'View overall statistics of your\nproducts below in the last',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF646161),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'icons/notifications.svg',
                  width: 32,
                  height: 32,
                  color: const Color(0xFF1e293b),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/order');
                },
                tooltip: 'Inbox',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
