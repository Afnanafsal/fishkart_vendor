import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/size_config.dart';
import 'dart:convert';
import 'dart:typed_data';

class VendorDashboardSummary extends StatefulWidget {
  const VendorDashboardSummary({Key? key}) : super(key: key);

  @override
  State<VendorDashboardSummary> createState() => _VendorDashboardSummaryState();
}

class _VendorDashboardSummaryState extends State<VendorDashboardSummary> {
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
        .collection('users')
        .doc(user.uid)
        .collection('ordered_products')
        .where('order_date', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('order_date', isLessThanOrEqualTo: to.toIso8601String())
        .get();
    return snapshot.size;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Return empty stream
      return const Stream.empty();
    }
    // Use collectionGroup to fetch all ordered_products for this vendor
    return FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<Map<String, dynamic>?> _fetchProduct(String productUid) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productUid)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> _approveOrder(DocumentSnapshot orderDoc) async {
    final data = orderDoc.data() as Map<String, dynamic>;
    final productUid = data['product_uid'] as String?;
    final quantity = data['quantity'] as int? ?? 1;
    if (productUid == null) return;
    final batch = FirebaseFirestore.instance.batch();
    // Update order status
    batch.update(orderDoc.reference, {'status': 'completed'});
    // Increment product ordered_count
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productUid);
    batch.update(productRef, {'ordered_count': FieldValue.increment(quantity)});
    await batch.commit();
  }

  Future<void> _rejectOrder(DocumentSnapshot orderDoc) async {
    await orderDoc.reference.update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last30d = now.subtract(const Duration(days: 30));
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(16),
        vertical: getProportionateScreenHeight(12),
      ),
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
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(24),
          vertical: getProportionateScreenHeight(28),
        ),
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
            SizedBox(height: getProportionateScreenHeight(24)),
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
            // Removed analytics section
            const SizedBox(height: 24),
            Divider(thickness: 1.2, color: Color(0xFFe0e7ef)),
            SizedBox(height: getProportionateScreenHeight(12)),
            Text(
              'Order Requests',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(18),
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            // Responsive ListView for order cards
            SizedBox(
              height: getProportionateScreenHeight(320),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _pendingOrdersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('Order Requests Error: \\${snapshot.error}');
                    return Text('Error: \\${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Text('No data received from Firestore.');
                  }
                  final orders = snapshot.data!.docs;
                  if (orders.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const Text('No pending order requests.')],
                    );
                  }
                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final data = order.data();
                      final productUid = data['product_uid'] as String?;
                      final userId = data['user_id'] as String?;
                      final quantity = data['quantity'] ?? 1;
                      final status = data['status'] ?? '';
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: productUid != null
                            ? _fetchProduct(productUid)
                            : Future.value(null),
                        builder: (context, productSnap) {
                          final product = productSnap.data;
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: userId != null
                                ? _fetchUser(userId)
                                : Future.value(null),
                            builder: (context, userSnap) {
                              final user = userSnap.data;
                              // Decode base64 image for product
                              Widget productAvatar;
                              if (product != null &&
                                  product['images'] != null &&
                                  product['images'] is List &&
                                  product['images'].isNotEmpty) {
                                try {
                                  Uint8List imgBytes = base64Decode(
                                    product['images'][0],
                                  );
                                  productAvatar = CircleAvatar(
                                    backgroundImage: MemoryImage(imgBytes),
                                    radius: 22,
                                  );
                                } catch (_) {
                                  productAvatar = CircleAvatar(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF6366f1),
                                    ),
                                    backgroundColor: Color(0xFFe0e7ff),
                                    radius: 22,
                                  );
                                }
                              } else {
                                productAvatar = CircleAvatar(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFF6366f1),
                                  ),
                                  backgroundColor: Color(0xFFe0e7ff),
                                  radius: 22,
                                );
                              }
                              // Decode base64 image for user
                              Widget userAvatar;
                              if (user != null &&
                                  user['display_picture'] != null) {
                                try {
                                  Uint8List userImgBytes = base64Decode(
                                    user['display_picture'],
                                  );
                                  userAvatar = CircleAvatar(
                                    backgroundImage: MemoryImage(userImgBytes),
                                    radius: 18,
                                  );
                                } catch (_) {
                                  userAvatar = CircleAvatar(
                                    child: Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF10b981),
                                    ),
                                    backgroundColor: Color(0xFFe0f7fa),
                                    radius: 18,
                                  );
                                }
                              } else {
                                userAvatar = CircleAvatar(
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF10b981),
                                  ),
                                  backgroundColor: Color(0xFFe0f7fa),
                                  radius: 18,
                                );
                              }
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          productAvatar,
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product != null
                                                      ? (product['title'] ??
                                                            'Product')
                                                      : 'Product',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (product != null &&
                                                    product['description'] !=
                                                        null)
                                                  Text(
                                                    product['description'],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748b),
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'x$quantity',
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          userAvatar,
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              user != null
                                                  ? (user['display_name'] ??
                                                        user['name'] ??
                                                        'User')
                                                  : 'User',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: status == 'pending'
                                                  ? () async {
                                                      await _approveOrder(
                                                        order,
                                                      );
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.check),
                                              label: const Text('Approve'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFF10b981,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: status == 'pending'
                                                  ? () async {
                                                      await _rejectOrder(order);
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.close),
                                              label: const Text('Reject'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Color(
                                                  0xFFef4444,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
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
