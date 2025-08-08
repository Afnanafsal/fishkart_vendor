import 'package:flutter/material.dart';

import 'package:fishkart_vendor/screens/home/components/home_header.dart';
import 'package:fishkart_vendor/screens/home/components/dashboard_stats_card.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last7d = now.subtract(const Duration(days: 7));
    return SingleChildScrollView(
      child: Column(
        children: [
          const HomeHeader(),
          DashboardStatsCard(),
          // Add other widgets for the home screen body below as needed
        ],
      ),
    );
  }
}
