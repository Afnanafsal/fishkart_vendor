import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorDashboardSummary extends StatelessWidget {
  const VendorDashboardSummary({Key? key}) : super(key: key);

  Future<int> _fetchProductCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('vendorId', isEqualTo: user.uid)
        .get();
    return snapshot.size;
  }

  Future<int> _fetchOrderCount({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: from)
        .where('createdAt', isLessThanOrEqualTo: to)
        .get();
    return snapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last30d = now.subtract(const Duration(days: 30));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Color(0xFFe0e7ff), Color(0xFFf8fafc)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_customize_rounded,
                  color: Color(0xFF6366f1),
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Color(0xFFE0E7EF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DashboardStat(
                      label: 'Products',
                      future: _fetchProductCount(),
                      icon: Icons.inventory_2_outlined,
                      color: Color(0xFF6366f1),
                    ),
                  ),
                  Container(width: 1.2, height: 64, color: Color(0xFFE0E7EF)),
                  Expanded(
                    child: _DashboardStat(
                      label: 'Orders (24h)',
                      future: _fetchOrderCount(from: last24h, to: now),
                      icon: Icons.shopping_cart_outlined,
                      color: Color(0xFF10b981),
                    ),
                  ),
                  Container(width: 1.2, height: 64, color: Color(0xFFE0E7EF)),
                  Expanded(
                    child: _DashboardStat(
                      label: 'Orders (30d)',
                      future: _fetchOrderCount(from: last30d, to: now),
                      icon: Icons.calendar_month_outlined,
                      color: Color(0xFFa21caf),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(thickness: 1.2, color: Color(0xFFe0e7ef)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                Icon(Icons.trending_up_rounded, color: Color(0xFF6366f1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your products and orders performance at a glance.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748b)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  final String label;
  final Future<int> future;
  final IconData icon;
  final Color color;

  const _DashboardStat({
    required this.label,
    required this.future,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.18),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          FutureBuilder<int>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 32,
                  height: 24,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Text(
                '${snapshot.data ?? 0}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
