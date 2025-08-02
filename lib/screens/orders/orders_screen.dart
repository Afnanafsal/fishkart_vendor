import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/providers/providers.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Riverpod OrdersScreen implementation
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final List<String> _filters = [
    'All orders',
    'Pending',
    'Accepted',
    'Shipped',
    'Delivered',
    'Rejected',
  ];
  int _selectedIndex = 0;
  List<bool> _expanded = [];
  void _resetExpansion(int length) {
    _expanded = List.generate(length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F6),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(AuthentificationService().currentUser.uid)
                          .get(),
                      builder: (context, snapshot) {
                        String name = 'Vendor';
                        if (snapshot.hasData && snapshot.data != null) {
                          final data = snapshot.data!.data();
                          if (data != null &&
                              (data['display_name'] ?? data['name']) != null) {
                            name = data['display_name'] ?? data['name'];
                          }
                        }
                        return Text(
                          'Hello $name!',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'View overall statistics of your products below in the last',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      _filters.length,
                      (i) => _buildTab(_filters[i], i == _selectedIndex, i),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ordersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                  data: (snapshot) {
                    final docs = snapshot.docs;
                    List<QueryDocumentSnapshot> normalizedDocs = docs.map((
                      doc,
                    ) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data != null &&
                          (data['status'] == null ||
                              (data['status'] as String).trim().isEmpty)) {
                        data['status'] = 'pending';
                      }
                      return doc;
                    }).toList();
                    final statusOrder = [
                      'pending',
                      'accepted',
                      'shipped',
                      'delivered',
                      'completed',
                      'rejected',
                    ];
                    normalizedDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>?;
                      final bData = b.data() as Map<String, dynamic>?;
                      String aStatus = (aData?['status'] ?? 'pending')
                          .toString()
                          .toLowerCase();
                      String bStatus = (bData?['status'] ?? 'pending')
                          .toString()
                          .toLowerCase();
                      int aIndex = statusOrder.indexOf(aStatus);
                      int bIndex = statusOrder.indexOf(bStatus);
                      if (aIndex == -1) aIndex = statusOrder.length;
                      if (bIndex == -1) bIndex = statusOrder.length;
                      if (aIndex != bIndex) return aIndex.compareTo(bIndex);
                      final aDateRaw = aData?['order_date'];
                      final bDateRaw = bData?['order_date'];
                      DateTime? aDate;
                      DateTime? bDate;
                      if (aDateRaw is Timestamp) aDate = aDateRaw.toDate();
                      if (aDateRaw is String)
                        aDate = DateTime.tryParse(aDateRaw);
                      if (bDateRaw is Timestamp) bDate = bDateRaw.toDate();
                      if (bDateRaw is String)
                        bDate = DateTime.tryParse(bDateRaw);
                      if (aDate == null && bDate == null) return 0;
                      if (aDate == null) return 1;
                      if (bDate == null) return -1;
                      return bDate.compareTo(aDate);
                    });
                    String selectedStatus = _filters[_selectedIndex]
                        .toLowerCase();
                    List<QueryDocumentSnapshot> filteredDocs;
                    if (_selectedIndex == 0) {
                      filteredDocs = List.from(normalizedDocs);
                    } else if (selectedStatus == 'delivered') {
                      filteredDocs = normalizedDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        if (data == null) return false;
                        String status = (data['status'] ?? 'pending')
                            .toString()
                            .toLowerCase();
                        return status == 'delivered' || status == 'completed';
                      }).toList();
                    } else {
                      filteredDocs = normalizedDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        if (data == null) return false;
                        String status = (data['status'] ?? 'pending')
                            .toString()
                            .toLowerCase();
                        return status == selectedStatus;
                      }).toList();
                    }
                    if (_expanded.length != filteredDocs.length) {
                      _resetExpansion(filteredDocs.length);
                    }
                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text('No orders found.'));
                    }
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final order =
                            filteredDocs[index].data() as Map<String, dynamic>;
                        final orderId = filteredDocs[index].id;
                        final isExpanded = _expanded[index];
                        final docRef = filteredDocs[index].reference;
                        return FutureBuilder<String>(
                          future: _fetchUserName(order['user_id']),
                          builder: (context, userSnapshot) {
                            final userName = userSnapshot.data ?? 'Customer';
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _expanded[index] = !isExpanded;
                                });
                              },
                              child: Column(
                                children: [
                                  _buildOrderCardHeader(
                                    orderId: orderId,
                                    status: order['status'] ?? '',
                                    time: _formatOrderDate(order['order_date']),
                                    items: order['quantity'],
                                    payment: order['payment'] ?? '',
                                    customerName: userName,
                                  ),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: _buildOrderCardExpanded(
                                      order,
                                      userName,
                                      docRef,
                                    ),
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatOrderDate(dynamic orderDate) {
    if (orderDate is Timestamp) {
      final dt = orderDate.toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (orderDate is String) {
      final dt = DateTime.tryParse(orderDate);
      if (dt != null) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    return '';
  }

  Future<String> _fetchUserName(String? userId) async {
    if (userId == null) return 'Customer';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Customer';
      }
    } catch (e) {}
    return 'Customer';
  }

  Widget _buildTab(String label, bool selected, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _resetExpansion(0); // Will be reset by StreamBuilder
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF6ED) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFB86C)
                  : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFFFFB86C)
                  : const Color(0xFF757575),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCardHeader({
    required String orderId,
    required String status,
    required String time,
    int? items,
    String? payment,
    String? customerName,
  }) {
    Color statusBgColor;
    Color statusBorderColor;
    Color statusTextColor;
    switch (status.toLowerCase()) {
      case 'pending':
        statusBgColor = const Color(0xFFFFF6ED);
        statusBorderColor = const Color(0xFFFFB86C);
        statusTextColor = const Color(0xFFFFB86C);
        break;
      case 'accepted':
        statusBgColor = const Color(0x1A4CAF50);
        statusBorderColor = const Color(0xFF4CAF50);
        statusTextColor = const Color(0xFF388E3C);
        break;
      case 'shipped':
        statusBgColor = const Color(0x1A2196F3);
        statusBorderColor = const Color(0xFF2196F3);
        statusTextColor = const Color(0xFF1976D2);
        break;
      case 'delivered':
      case 'completed':
        statusBgColor = const Color(0x1A8BC34A);
        statusBorderColor = const Color(0xFF8BC34A);
        statusTextColor = const Color(0xFF558B2F);
        break;
      case 'rejected':
        statusBgColor = const Color(0x1AFF0000);
        statusBorderColor = const Color(0xFFFF0000);
        statusTextColor = const Color(0xFFFF0000);
        break;
      default:
        statusBgColor = Colors.white;
        statusBorderColor = const Color(0xFFE0E0E0);
        statusTextColor = const Color(0xFF757575);
    }
    String statusDisplay =
        (status.toLowerCase() == 'completed' ||
            status.toLowerCase() == 'delivered')
        ? 'Delivered'
        : status;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID #$orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (customerName != null && customerName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      time, // time is formatted as HH:mm
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusBorderColor, width: 1.5),
                ),
                child: Text(
                  statusDisplay,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (items != null)
                Text(
                  '${items.toString().padLeft(2, '0')} Items',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              const Spacer(),
              if (payment != null)
                Text(
                  payment,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCardExpanded(
    Map<String, dynamic> order,
    String userName,
    DocumentReference docRef,
  ) {
    // TODO: Fetch product details from Firestore if needed
    Widget? actionButton;
    switch ((order['status'] ?? '').toString().toLowerCase()) {
      case 'pending':
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {},
          child: const Text(
            'Accept',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
        break;
      case 'accepted':
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {},
          child: const Text(
            'Ship',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
        break;
      case 'shipped':
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {},
          child: const Text(
            'Mark as Delivered',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
        break;
      case 'delivered':
      case 'completed':
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: null,
          child: const Text(
            'Delivered',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
        break;
      case 'rejected':
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFE0E0),
            foregroundColor: const Color(0xFFFF0000),
            disabledBackgroundColor: const Color(0xFFFFE0E0),
            disabledForegroundColor: const Color(0xFFFF0000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: null,
          child: const Text(
            'Rejected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
        break;
      default:
        actionButton = null;
    }

    // Fetch product, user, and address details for expanded view
    final productUid = order['product_uid'];
    final userId = order['user_id'];
    final addressId = order['address_id'];
    Future<DocumentSnapshot<Map<String, dynamic>>> _dummyDoc(
      String collection,
    ) async {
      // Return a DocumentSnapshot with null data for compatibility
      return await FirebaseFirestore.instance
          .collection(collection)
          .doc('___dummy___')
          .get();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: productUid != null
          ? FirebaseFirestore.instance
                .collection('products')
                .doc(productUid)
                .get()
          : _dummyDoc('products'),
      builder: (context, productSnap) {
        final product = productSnap.data?.data();
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: userId != null
              ? FirebaseFirestore.instance.collection('users').doc(userId).get()
              : _dummyDoc('users'),
          builder: (context, userSnap) {
            final user = userSnap.data?.data();
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: addressId != null
                  ? FirebaseFirestore.instance
                        .collection('addresses')
                        .doc(addressId)
                        .get()
                  : _dummyDoc('addresses'),
              builder: (context, addressSnap) {
                final address = addressSnap.data?.data();
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OrderActionButton(
                            icon: Icons.edit,
                            label: 'Edit Items',
                            onPressed: () {},
                          ),
                          _OrderActionButton(
                            icon: Icons.print,
                            label: 'Print Invoice',
                            onPressed: () async {
                              final pdf = pw.Document();
                              pdf.addPage(
                                pw.Page(
                                  build: (pw.Context context) => pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Order Invoice',
                                        style: pw.TextStyle(
                                          fontSize: 24,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 16),
                                      pw.Text('Order ID: ${docRef.id}'),
                                      pw.Text(
                                        'Customer: '
                                        '${user != null && ((user['display_name'] ?? user['name'])?.toString().isNotEmpty ?? false) ? (user['display_name'] ?? user['name']) : (userName != 'Customer' ? userName : '')}',
                                      ),
                                      if (product != null) ...[
                                        pw.Text(
                                          'Product: ${product['title'] ?? ''}',
                                        ),
                                        pw.Text(
                                          'Qty: ${order['quantity'] ?? 1}',
                                        ),
                                        if (product['price'] != null)
                                          pw.Text(
                                            'Price: ₹${product['price']}',
                                          ),
                                      ],
                                      if (address != null &&
                                          (address['address_line'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                        pw.Text(
                                          'Address: ${address['address_line']}',
                                        ),
                                      pw.Text(
                                        'Payment: ${order['payment'] ?? ''}',
                                      ),
                                      pw.Text(
                                        'Status: ${order['status'] ?? ''}',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              await Printing.layoutPdf(
                                onLayout: (format) async => pdf.save(),
                                name: 'order_${docRef.id}.pdf',
                              );
                            },
                          ),
                          _OrderActionButton(
                            icon: Icons.delete,
                            label: 'Delete',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Order'),
                                  content: const Text(
                                    'Are you sure you want to delete this order?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await docRef.delete();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Order deleted.'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      // Product details
                      if (product != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product['title'] ?? 'Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'x${order['quantity'] ?? 1}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (product['description'] ?? '')
                                            .toString()
                                            .length >
                                        30
                                    ? (product['description'] as String)
                                              .substring(0, 30) +
                                          '...'
                                    : (product['description'] ?? ''),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF757575),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (product['price'] != null)
                              Text(
                                '₹${product['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Customer and payment info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user != null &&
                                        ((user['display_name'] ?? user['name'])
                                                ?.toString()
                                                .isNotEmpty ??
                                            false)
                                    ? (user['display_name'] ?? user['name'])
                                    : (userName != 'Customer' ? userName : ''),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              if (address != null &&
                                  (address['address_line'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  address['address_line'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF757575),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF757575),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order['payment'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (actionButton != null)
                        SizedBox(width: double.infinity, child: actionButton),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _OrderActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
