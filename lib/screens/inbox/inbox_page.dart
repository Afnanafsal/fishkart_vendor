import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/size_config.dart';
import 'dart:convert';
import 'dart:typed_data';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final Set<String> _expandedOrders = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('order_date', descending: true)
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
    batch.update(orderDoc.reference, {'status': 'completed'});
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productUid);
    batch.update(productRef, {'ordered_count': FieldValue.increment(quantity)});
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order approved successfully!'),
          backgroundColor: Color(0xFF10b981),
        ),
      );
    }
  }

  Future<void> _rejectOrder(DocumentSnapshot orderDoc) async {
    await orderDoc.reference.update({'status': 'rejected'});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected!'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
    }
  }

  String _formatOrderDate(dynamic orderDate) {
    if (orderDate == null) return '';

    try {
      DateTime dateTime;
      if (orderDate is String) {
        dateTime = DateTime.parse(orderDate);
      } else if (orderDate is Timestamp) {
        dateTime = orderDate.toDate();
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1e293b),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pendingOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No pending orders."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data();
              final productUid = data['product_uid'] ?? '';
              final userId = data['user_id'] ?? '';
              final quantity = data['quantity'] ?? 1;
              final status = data['status'];
              final orderDate = data['order_date'];
              final isExpanded = _expandedOrders.contains(order.id);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchProduct(productUid),
                builder: (context, productSnap) {
                  final product = productSnap.data;
                  final productTitle = product?['title'] ?? 'Product';
                  final productDescription =
                      product?['description'] ?? 'No description';
                  Widget productImage;

                  try {
                    Uint8List imgBytes = base64Decode(
                      product?['images']?[0] ?? '',
                    );
                    productImage = CircleAvatar(
                      backgroundImage: MemoryImage(imgBytes),
                      radius: 26,
                    );
                  } catch (_) {
                    productImage = const CircleAvatar(
                      backgroundColor: Color(0xFFe0e7ff),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF6366f1),
                      ),
                      radius: 26,
                    );
                  }

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchUser(userId),
                    builder: (context, userSnap) {
                      final user = userSnap.data;
                      final displayName =
                          user?['display_name'] ?? user?['name'] ?? 'Customer';
                      Widget userAvatar;
                      try {
                        Uint8List img = base64Decode(
                          user?['display_picture'] ?? '',
                        );
                        userAvatar = CircleAvatar(
                          backgroundImage: MemoryImage(img),
                          radius: 14,
                        );
                      } catch (_) {
                        userAvatar = const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFFe0f7fa),
                          child: Icon(
                            Icons.person_outline,
                            color: Color(0xFF10b981),
                            size: 16,
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedOrders.remove(order.id);
                            } else {
                              _expandedOrders.add(order.id);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Color(0xFFe0e7ff)),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  productImage,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      productTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF1e293b),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366f1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'x$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 12),
                                Text(
                                    productDescription.length > 80
                                      ? '${productDescription.substring(0, 80)}...'
                                      : productDescription,
                                  style: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    userAvatar,
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ordered by ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Color(0xFF334155),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatOrderDate(orderDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: status == 'pending'
                                            ? () async {
                                                await _approveOrder(order);
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF10b981,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFef4444,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFef4444),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }
}
