import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/size_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          height: 32.h,
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
        ),
        Container(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 0,
            bottom: 16.h,
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
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1e293b),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'View overall statistics of your\nproducts below in the last',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: const Color(0xFF646161),
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
                  'assets/icons/notifications.svg',
                  width: 32.w,
                  height: 32.w,
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
