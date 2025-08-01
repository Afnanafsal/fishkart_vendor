import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

class RecentOrdersList extends StatelessWidget {
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

  const RecentOrdersList({Key? key}) : super(key: key);

  Stream<QuerySnapshot<Map<String, dynamic>>> _recentOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    // Use collectionGroup to fetch all completed ordered_products for this vendor
    return FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.receipt_long_rounded, color: Color(0xFF6366f1)),
                SizedBox(width: 8),
                Text(
                  'Recent Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _recentOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No recent orders.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                final orders = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (context, i) => const Divider(height: 18),
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    final data = order.data() as Map<String, dynamic>;
                    final productUid = data['product_uid'] as String?;
                    final userId = data['user_id'] as String?;
                    final quantity = data['quantity'] ?? 1;
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
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          style: const TextStyle(fontSize: 15),
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.withOpacity(0.15);
      case 'cancelled':
        return Colors.red.withOpacity(0.15);
      case 'pending':
      default:
        return Colors.orange.withOpacity(0.15);
    }
  }
}
