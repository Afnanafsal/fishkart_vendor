import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardStatsCard extends StatefulWidget {
  const DashboardStatsCard({Key? key}) : super(key: key);

  @override
  State<DashboardStatsCard> createState() => _DashboardStatsCardState();
}

class _DashboardStatsCardState extends State<DashboardStatsCard> {
  int selectedFilter = 1; // 0: Today, 1: 7 Days, 2: 30 Days, 3: 90 Days

  List<Map<String, dynamic>> statsData = [
    // Today
    {
      'totalOrders': 0,
      'totalSale': '₹0',
      'totalProducts': 0, // will be updated
      'totalOrdersChange': 0.0,
      'totalSaleChange': 0.0,
      'totalProductsChange': 0.0,
      'totalOrdersUp': false,
      'totalSaleUp': false,
      'totalProductsUp': false,
      'pendingOrders': 0,
      'shippedOrders': 0,
      'deliveredOrders': 0,
    },
    // 7 Days
    {
      'totalOrders': 0,
      'totalSale': '₹0',
      'totalProducts': 0, // will be updated
      'totalOrdersChange': 0.0,
      'totalSaleChange': 0.0,
      'totalProductsChange': 0.0,
      'totalOrdersUp': false,
      'totalSaleUp': false,
      'totalProductsUp': false,
      'pendingOrders': 0,
      'shippedOrders': 0,
      'deliveredOrders': 0,
    },
    // 30 Days
    {
      'totalOrders': 0,
      'totalSale': '₹0',
      'totalProducts': 0, // will be updated
      'totalOrdersChange': 0.0,
      'totalSaleChange': 0.0,
      'totalProductsChange': 0.0,
      'totalOrdersUp': false,
      'totalSaleUp': false,
      'totalProductsUp': false,
      'pendingOrders': 0,
      'shippedOrders': 0,
      'deliveredOrders': 0,
    },
    // 90 Days
    {
      'totalOrders': 0,
      'totalSale': '₹0',
      'totalProducts': 0, // will be updated
      'totalOrdersChange': 0.0,
      'totalSaleChange': 0.0,
      'totalProductsChange': 0.0,
      'totalOrdersUp': false,
      'totalSaleUp': false,
      'totalProductsUp': false,
      'pendingOrders': 0,
      'shippedOrders': 0,
      'deliveredOrders': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchAndSetVendorProductCount();
    fetchAndSetVendorOrderStats();
  }

  Future<void> fetchAndSetVendorProductCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('vendorId', isEqualTo: user.uid)
        .get();
    final int count = querySnapshot.docs.length;
    setState(() {
      for (var data in statsData) {
        data['totalProducts'] = count;
      }
    });
  }

  Future<void> fetchAndSetVendorOrderStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Since ordered_products is a subcollection under each user, we need to query all users' ordered_products
    // Firestore does not support cross-user subcollection queries without a collectionGroup
    // So we use collectionGroup query
    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .get();

    int totalOrders = querySnapshot.docs.length;
    int pendingOrders = 0;
    int shippedOrders = 0;
    int deliveredOrders = 0;

    for (var doc in querySnapshot.docs) {
      final status = doc['status']?.toString().toLowerCase();
      if (status == 'pending') {
        pendingOrders++;
      } else if (status == 'shipped') {
        shippedOrders++;
      } else if (status == 'delivered' || status == 'completed') {
        deliveredOrders++;
      }
    }

    setState(() {
      for (var data in statsData) {
        data['totalOrders'] = totalOrders;
        data['pendingOrders'] = pendingOrders;
        data['shippedOrders'] = shippedOrders;
        data['deliveredOrders'] = deliveredOrders;
        // Optionally clear the dummy change/up values for clarity
        data['totalOrdersChange'] = 0.0;
        data['totalOrdersUp'] = false;
      }
    });

    // Debug prints
    print('Current user UID: ${user.uid}');
    print('Fetched docs: ${querySnapshot.docs.length}');
    for (var doc in querySnapshot.docs.take(3)) {
      print('Doc vendor_id: ${doc['vendor_id']} status: ${doc['status']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = statsData[selectedFilter];
    final int totalOrders = data['totalOrders'] ?? 0;
    final String totalSale = data['totalSale'] ?? '';
    final int totalProducts = data['totalProducts'] ?? 0;
    final int pendingOrders = data['pendingOrders'] ?? 0;
    final int shippedOrders = data['shippedOrders'] ?? 0;
    final int deliveredOrders = data['deliveredOrders'] ?? 0;

    double safePercent(int part, int total) {
      if (total == 0) return 0.0;
      return part / total;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton("Today", 0),
                        const SizedBox(width: 8),
                        _buildFilterButton("7 Days", 1),
                        const SizedBox(width: 8),
                        _buildFilterButton("30 Days", 2),
                        const SizedBox(width: 8),
                        _buildFilterButton("90 Days", 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 20, color: Color(0xFF64748b)),
              ],
            ),
            const SizedBox(height: 20),
            // Stat cards in a column, not a row or wrap
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        title: "Total Orders",
                        value: totalOrders.toString(),
                        percent: data['totalOrdersChange'],
                        isUp: data['totalOrdersUp'],
                        icon: Icons.shopping_cart,
                        color: Color(0xFF2563eb),
                        subtitle: "vs last 7 days",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatBox(
                        title: "Total Sale",
                        value: totalSale,
                        percent: data['totalSaleChange'],
                        isUp: data['totalSaleUp'],
                        icon: Icons.currency_rupee,
                        color: Color(0xFF0d9488),
                        subtitle: "vs last 7 days",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        title: "Total Products",
                        value: totalProducts.toString(),
                        percent: data['totalProductsChange'],
                        isUp: data['totalProductsUp'],
                        icon: Icons.inventory_2,
                        color: Color(0xFF6366f1),
                        subtitle: "vs last 7 days",
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Order Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFe0e7ff)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderProgress(
                    label: "Pending Orders",
                    percent: safePercent(pendingOrders, totalOrders),
                    value: pendingOrders,
                    total: totalOrders,
                    color: Color(0xFFfbbf24),
                  ),
                  const SizedBox(height: 24),
                  _buildOrderProgress(
                    label: "Shipped Orders",
                    percent: safePercent(shippedOrders, totalOrders),
                    value: shippedOrders,
                    total: totalOrders,
                    color: Color(0xFFa78bfa),
                  ),
                  const SizedBox(height: 24),
                  _buildOrderProgress(
                    label: "Delivered Orders",
                    percent: safePercent(deliveredOrders, totalOrders),
                    value: deliveredOrders,
                    total: totalOrders,
                    color: Color(0xFF34d399),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, int index) {
    final bool selected = selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Color(0xFFf1f5f9) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Color(0xFF2563eb) : Color(0xFFe2e8f0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Color(0xFF2563eb) : Color(0xFF64748b),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required double percent,
    required bool isUp,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe0e7ff)),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isUp ? Color(0xFF22c55e) : Color(0xFFef4444),
                    size: 18,
                  ),
                  Text(
                    "${(percent.abs() * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: isUp ? Color(0xFF22c55e) : Color(0xFFef4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderProgress({
    required String label,
    required double percent,
    required int value,
    required int total,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${(percent * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                "$value/$total Orders",
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748b),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFf1f5f9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
