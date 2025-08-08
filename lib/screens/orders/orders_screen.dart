import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/providers/providers.dart';

// Removed unused PDF and printing imports
import 'package:fishkart_vendor/screens/invoice/pdfinvoice.dart';
import 'package:flutter_svg/svg.dart';

// Riverpod OrdersScreen implementation
class OrdersScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const OrdersScreen({Key? key, this.initialTabIndex = 1}) : super(key: key);
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  Color _getStatusBgColor(dynamic status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFE5B2); // light orange
      case 'accepted':
        return const Color(0xFFBBDEFB); // light blue
      case 'shipped':
        return const Color(0xFFC8E6C9); // light green
      case 'delivered':
      case 'completed':
        return const Color(0xFFE0E0E0); // light gray
      case 'rejected':
        return const Color(0x1AFF0000);
      default:
        return Colors.white;
    }
  }

  Color _getStatusBorderColor(dynamic status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFB86C); // orange border
      case 'accepted':
        return const Color(0xFF1976D2); // blue border
      case 'shipped':
        return const Color(0xFF4CAF50); // green border
      case 'delivered':
      case 'completed':
        return const Color(0xFFBDBDBD); // gray border
      case 'rejected':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getStatusTextColor(dynamic status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'pending':
        return const Color(0xFFB86C00); // dark orange
      case 'accepted':
        return const Color(0xFF1976D2); // blue
      case 'shipped':
        return const Color(0xFF087F23); // dark green
      case 'delivered':
      case 'completed':
        return Colors.black; // black text for delivered
      case 'rejected':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusDisplay(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    if (s == 'completed' || s == 'delivered') return 'Delivered';
    if (s.isEmpty) return 'Pending'; // Default to Pending instead of empty
    return s[0].toUpperCase() + s.substring(1);
  }

  final List<String> _filters = [
    'All orders',
    'Pending',
    'Accepted',
    'Shipped',
    'Delivered',
    'Rejected',
  ];

  final List<String> _statusOptions = [
    "Pending",
    "Accepted",
    "Shipped",
    "Delivered",
  ];

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  @override
  void dispose() {
    // Clean up any resources here
    super.dispose();
  }

  List<bool> _expanded = [];
  void _resetExpansion(int length) {
    _expanded = List.generate(length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
                        color: Color(0xFF646161),
                        fontSize: 16,
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
                        final shortOrderId = orderId.substring(
                          0,
                          orderId.length > 12 ? 12 : orderId.length,
                        );
                        final isExpanded = _expanded[index];
                        final docRef = filteredDocs[index].reference;
                        return FutureBuilder<String>(
                          future: _fetchUserName(order['user_id']),
                          builder: (context, userSnapshot) {
                            final userName = userSnapshot.data ?? 'Customer';
                            return GestureDetector(
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    _expanded[index] = !isExpanded;
                                  });
                                }
                              },
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      24,
                                    ), // Increased radius
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 8,
                                        color: Colors.black.withOpacity(
                                          0.08,
                                        ), // Slightly more visible, no offset
                                        offset: const Offset(0, 0), // No offset
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        children: [
                                          // Order ID (truncated to 8 chars)
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Order ID #${shortOrderId.substring(0, shortOrderId.length > 8 ? 8 : shortOrderId.length)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          // Center time only when expanded
                                          if (isExpanded)
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  _formatOrderDate(
                                                    order['order_date'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: Color(0xFF757575),
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            const Spacer(),
                                          // Status Dropdown - FIXED
                                          _buildStatusDropdown(
                                            order,
                                            filteredDocs[index],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Only show quantity/items/payment row if not expanded (no time)
                                      if (!isExpanded)
                                        Row(
                                          children: [
                                            Text(
                                              '${order['quantity'].toString().padLeft(2, '0')} Items',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _formatOrderDate(
                                                    order['order_date'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: Color(0xFF000000),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if ((order['status'] ?? '')
                                                    .toString()
                                                    .toLowerCase() !=
                                                'rejected')
                                              const Text(
                                                'Paid',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (isExpanded)
                                        _buildOrderCardExpanded(
                                          order,
                                          userName,
                                          docRef,
                                        ),
                                    ],
                                  ),
                                ),
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

  // Fixed status dropdown widget
  Widget _buildStatusDropdown(
    Map<String, dynamic> order,
    QueryDocumentSnapshot doc,
  ) {
    final currentStatus = _getStatusDisplay(order['status']);

    // Ensure current status is in the options list
    final availableOptions = List<String>.from(_statusOptions);
    if (!availableOptions.contains(currentStatus)) {
      availableOptions.add(currentStatus);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 28, maxHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: _getStatusBgColor(order['status']),
        borderRadius: BorderRadius.circular(32),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          isDense: true,
          style: TextStyle(
            color: _getStatusTextColor(order['status']),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: availableOptions
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _getStatusTextColor(value),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (String? newValue) async {
            if (newValue != null && newValue != currentStatus && mounted) {
              try {
                String statusValue = newValue.toLowerCase();
                await doc.reference.update({'status': statusValue});
                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating status: $e')),
                  );
                }
              }
            }
          },
          dropdownColor: Colors.white,
          icon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SvgPicture.asset(
              'assets/icons/arrow-up.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                _getStatusTextColor(order['status']),
                BlendMode.srcIn,
              ),
            ),
          ),
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
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    return 'Customer';
  }

  Widget _buildTab(String label, bool selected, int index) {
    Color bgColor;
    Color textColor;
    switch (label.toLowerCase()) {
      case 'pending':
        bgColor = selected
            ? const Color(0xFFFFE5B2)
            : Colors.white; // lighter orange
        textColor = selected
            ? const Color(0xFFB86C00)
            : const Color(0xFF757575);
        break;
      case 'accepted':
        bgColor = selected
            ? const Color(0xFFBBDEFB)
            : Colors.white; // lighter blue
        textColor = selected
            ? const Color(0xFF0D47A1)
            : const Color(0xFF757575);
        break;
      case 'shipped':
        bgColor = selected
            ? const Color(0xFFC8E6C9)
            : Colors.white; // lighter green
        textColor = selected
            ? const Color(0xFF087F23)
            : const Color(0xFF757575);
        break;
      case 'delivered':
        bgColor = selected ? const Color(0xFFE0E0E0) : Colors.white;
        textColor = selected ? Colors.black : const Color(0xFF757575);
        break;
      case 'rejected':
        bgColor = selected
            ? const Color(0xFFFFCDD2)
            : Colors.white; // lighter red
        textColor = selected
            ? const Color(0xFFB00000)
            : const Color(0xFF757575);
        break;
      case 'all orders':
        bgColor = selected ? Colors.black : Colors.white;
        textColor = selected ? Colors.white : const Color(0xFF757575);
        break;
      default:
        bgColor = selected ? const Color(0xFFE0E0E0) : Colors.white;
        textColor = selected ? Colors.black : const Color(0xFF757575);
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedIndex = index;
              _resetExpansion(0); // Will be reset by StreamBuilder
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? bgColor : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.normal,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCardExpanded(
    Map<String, dynamic> order,
    String userName,
    DocumentReference docRef,
  ) {
    String status = (order['status'] ?? '').toString().toLowerCase();
    Widget? actionButton;
    // Normalize status for robust comparison
    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus == 'pending') {
      actionButton = Center(
        child: SizedBox(
          width: 380,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28),
              elevation: 0,
            ),
            onPressed: () async {
              if (!mounted) return;
              try {
                await docRef.update({'status': 'accepted'});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order accepted.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(
              'Accept',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else if (normalizedStatus == 'accepted') {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7EE6A4), // pill green
          foregroundColor: const Color(0xFF087F23),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: () async {
          if (!mounted) return;
          try {
            await docRef.update({'status': 'shipped'});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order marked as shipped.')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
        child: const Text(
          'Ship',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF087F23),
          ),
        ),
      );
    } else if (normalizedStatus == 'shipped') {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE), // light red
          foregroundColor: const Color(0xFFD32F2F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: () => _showDeleteConfirmation(docRef),
        child: const Text(
          'Delete',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD32F2F),
          ),
        ),
      );
    } else if (normalizedStatus == 'completed' ||
        normalizedStatus == 'delivered') {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0), // pill gray
          foregroundColor: const Color(0xFFBDBDBD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: null,
        child: const Text(
          'Delivered',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFBDBDBD),
          ),
        ),
      );
    } else if (normalizedStatus == 'rejected') {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE), // light red
          foregroundColor: const Color(0xFFD32F2F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: () => _showDeleteConfirmation(docRef),
        child: const Text(
          'Delete',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD32F2F),
          ),
        ),
      );
    }

    final productUid = order['product_uid'];
    final userId = order['user_id'];
    final addressId = order['address_id'];

    Future<DocumentSnapshot<Map<String, dynamic>>> _dummyDoc(
      String collection,
    ) async {
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
        dynamic price = product?['price'];
        if (price == null && order['price'] != null) {
          price = order['price'];
        }
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: userId != null
              ? FirebaseFirestore.instance.collection('users').doc(userId).get()
              : _dummyDoc('users'),
          builder: (context, userSnap) {
            final user = userSnap.data?.data();
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: (addressId != null && userId != null)
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
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
                  padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Details row (middle)
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OrderActionButton(
                            icon: Icons.print,
                            label: 'Print Invoice',
                            onPressed: () async {
                              try {
                                await PDFInvoiceGenerator.generateAndDownloadInvoice(
                                  order: {...order, 'price': price},
                                  product: product != null
                                      ? {...product, 'price': price}
                                      : null,
                                  user: user,
                                  address: address,
                                  docRefId: docRef.id,
                                  userName: userName,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error generating invoice: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _OrderActionButton(
                            icon: Icons.delete_forever_outlined,
                            label: 'Reject',
                            onPressed: () => _showDeleteConfirmation(docRef),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      if (product != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    (product['title'] ?? 'Product')
                                                .toString()
                                                .length >
                                            12
                                        ? (product['title'] as String)
                                                  .substring(0, 12) +
                                              '...'
                                        : (product['title'] ?? 'Product'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(width: 24),
                                  if (product['variant'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        product['variant'].toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'x${order['quantity'] ?? 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (product['price'] != null)
                              Flexible(
                                child: Text(
                                  '₹${product['price']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 0),
                      ],
                      const Divider(),
                      const SizedBox(height: 16),

                      // Customer Details (bottom)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null &&
                                          ((user['display_name'] ??
                                                      user['name'])
                                                  ?.toString()
                                                  .isNotEmpty ??
                                              false)
                                      ? (user['display_name'] ?? user['name'])
                                      : (userName != 'Customer'
                                            ? userName
                                            : ''),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                if (user != null &&
                                    (user['phone'] ?? '').toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      user['phone'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                // Show address line below phone number
                                Builder(
                                  builder: (context) {
                                    String addressLine = '';

                                    // Prefer address from address document
                                    if (address != null) {
                                      final fields = [
                                        'address_line_1',
                                        'city',
                                        'pincode',
                                      ];
                                      List<String> parts = [];

                                      for (final field in fields) {
                                        var value = address[field];
                                        if (value != null) {
                                          String cleaned = value is String
                                              ? value
                                                    .replaceAll(
                                                      RegExp(r'\s+'),
                                                      ' ',
                                                    )
                                                    .trim()
                                              : value.toString().trim();
                                          if (cleaned.isNotEmpty &&
                                              cleaned.toLowerCase() != 'null')
                                            parts.add(cleaned);
                                        }
                                      }
                                      addressLine = parts.join(', ');
                                    }

                                    // Fallback to user document address if address doc is empty
                                    if (addressLine.isEmpty && user != null) {
                                      final userAddress =
                                          (user['address_line'] ?? '')
                                              .toString()
                                              .trim();
                                      if (userAddress.isNotEmpty) {
                                        addressLine = userAddress;
                                      }
                                    }

                                    // Show address or helpful message
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: addressLine.isNotEmpty
                                          ? Text(
                                              addressLine,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF757575),
                                              ),
                                              maxLines: 5,
                                              overflow: TextOverflow.visible,
                                            )
                                          : const Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'No address found for this order.',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Color(
                                                            0xFF757575,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF757575),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (order['payment'] ?? 'Paid').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 28),

                      // Full width action button below customer/payment row
                      if (actionButton != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: actionButton,
                          ),
                        ),
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

  // Helper method to show delete confirmation dialog
  Future<void> _showDeleteConfirmation(DocumentReference docRef) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await docRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Order deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting order: $e')));
        }
      }
    }
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
