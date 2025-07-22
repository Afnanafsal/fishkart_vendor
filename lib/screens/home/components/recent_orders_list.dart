import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentOrdersList extends StatelessWidget {
  const RecentOrdersList({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _recentOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    final now = DateTime.now();
    final last7d = now.subtract(const Duration(days: 7));
    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: last7d)
        .orderBy('createdAt', descending: true)
        .limit(5)
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
                    final createdAt = (data['createdAt'] as Timestamp?)
                        ?.toDate();
                    final productName = data['productName'] ?? 'Product';
                    final customer = data['customerName'] ?? 'Customer';
                    final status = data['status'] ?? 'Pending';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF6366f1,
                        ).withOpacity(0.12),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFF6366f1),
                        ),
                      ),
                      title: Text(
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'To: $customer\n${createdAt != null ? _formatDate(createdAt) : ''}',
                      ),
                      trailing: Chip(
                        label: Text(
                          status,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: _statusColor(status),
                      ),
                      isThreeLine: true,
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
