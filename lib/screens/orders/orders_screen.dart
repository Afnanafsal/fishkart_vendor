import 'package:flutter/material.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<String> _filters = [
    'All orders',
    'Pending',
    'Accepted',
    'Shipped',
    'Delivered',
  ];
  int _selectedIndex = 0;

  // Dummy order data for demonstration
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '12452',
      'items': 2,
      'status': 'Pending',
      'time': '2:28 PM',
      'payment': 'Paid',
    },
    {
      'id': '12453',
      'items': 1,
      'status': 'Accepted',
      'time': '3:10 PM',
      'payment': 'Paid',
    },
    {
      'id': '12454',
      'items': 3,
      'status': 'Shipped',
      'time': '4:00 PM',
      'payment': 'Paid',
    },
    {
      'id': '12455',
      'items': 1,
      'status': 'Delivered',
      'time': '5:00 PM',
      'payment': 'Paid',
    },
    {
      'id': '12456',
      'items': 2,
      'status': 'Pending',
      'time': '6:00 PM',
      'payment': 'Paid',
    },
    {
      'id': '12457',
      'items': 2,
      'status': 'Accepted',
      'time': '7:00 PM',
      'payment': 'Paid',
    },
    {
      'id': '12458',
      'items': 2,
      'status': 'Shipped',
      'time': '8:00 PM',
      'payment': 'Paid',
    },
    {
      'id': '12459',
      'items': 2,
      'status': 'Delivered',
      'time': '9:00 PM',
      'payment': 'Paid',
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedIndex == 0) return _orders;
    return _orders
        .where((order) => order['status'] == _filters[_selectedIndex])
        .toList();
  }

  List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(_orders.length, (index) => false);
  }

  void _resetExpansion() {
    _expanded = List.generate(_filteredOrders.length, (index) => false);
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetExpansion();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = AuthentificationService().currentUser.displayName ?? "";
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
                    Text(
                      'Hello ${displayName.isNotEmpty ? displayName : ''}!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
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
                child: StatefulBuilder(
                  builder: (context, setStateSB) {
                    if (_expanded.length != _filteredOrders.length) {
                      _expanded = List.generate(
                        _filteredOrders.length,
                        (index) => false,
                      );
                    }
                    return ListView.builder(
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        final isExpanded = _expanded[index];
                        return GestureDetector(
                          onTap: () {
                            setStateSB(() {
                              _expanded[index] = !isExpanded;
                            });
                          },
                          child: Column(
                            children: [
                              _buildOrderCardHeader(
                                orderId: order['id'],
                                status: order['status'],
                                time: order['time'],
                                items: order['items'],
                                payment: order['payment'],
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: _buildOrderCardExpanded(order),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool selected, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _resetExpansion();
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
  }) {
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
                child: Text(
                  'Order ID #$orderId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status == 'Pending'
                      ? const Color(0xFFFFF6ED)
                      : status == 'Accepted'
                      ? const Color(0x1A4CAF50)
                      : status == 'Shipped'
                      ? const Color(0x1A2196F3)
                      : status == 'Delivered'
                      ? const Color(0x1A8BC34A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: status == 'Pending'
                        ? const Color(0xFFFFB86C)
                        : status == 'Accepted'
                        ? const Color(0xFF4CAF50)
                        : status == 'Shipped'
                        ? const Color(0xFF2196F3)
                        : status == 'Delivered'
                        ? const Color(0xFF8BC34A)
                        : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Pending'
                        ? const Color(0xFFFFB86C)
                        : status == 'Accepted'
                        ? const Color(0xFF388E3C)
                        : status == 'Shipped'
                        ? const Color(0xFF1976D2)
                        : status == 'Delivered'
                        ? const Color(0xFF558B2F)
                        : const Color(0xFF757575),
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
              Text(
                time,
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

  Widget _buildOrderCardExpanded(Map<String, dynamic> order) {
    // Dummy product list for demonstration
    final List<Map<String, dynamic>> products = [
      {'name': 'Seer Fish Steak', 'weight': '500 gms', 'qty': 2},
      {'name': 'Seer Fish Steak', 'weight': '500 gms', 'qty': 1},
      {'name': 'Seer Fish Steak', 'weight': '500 gms', 'qty': 3},
    ];
    Widget? actionButton;
    switch (order['status']) {
      case 'Pending':
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
      case 'Accepted':
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
      case 'Shipped':
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
      case 'Delivered':
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
      default:
        actionButton = null;
    }
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
              _OrderActionButton(icon: Icons.edit, label: 'Edit Items'),
              _OrderActionButton(icon: Icons.print, label: 'Print Invoice'),
              _OrderActionButton(icon: Icons.delete, label: 'Delete'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...products.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p['name'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p['weight'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'x${p['qty'].toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Customer name', style: TextStyle(fontSize: 15)),
                  SizedBox(height: 2),
                  Text(
                    '9142 3345 12',
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Address line, address, xyz',
                    style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(fontSize: 15, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order['payment'],
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
  }
}

class _OrderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OrderActionButton({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
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
