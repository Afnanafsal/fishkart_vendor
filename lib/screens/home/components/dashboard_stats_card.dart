import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:async';

class DashboardStatsCard extends StatefulWidget {
  const DashboardStatsCard({super.key});

  @override
  State<DashboardStatsCard> createState() => _DashboardStatsCardState();
}

class _DashboardStatsCardState extends State<DashboardStatsCard> {
  Map<String, dynamic>? customStatsData;
  DateTimeRange? customDateRange;
  int selectedFilter = 0; // 0: Today, 1: 7 Days, 2: 30 Days, 3: 90 Days

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
    // Load cached stats instantly
    _loadCachedStats();
    // Listen for real-time updates
    _listenToOrderStats();
  }

  void _loadCachedStats() async {
    var box = await Hive.openBox('dashboard_stats');
    final cached = box.get('statsData');
    if (cached != null && cached is List) {
      setState(() {
        for (int i = 0; i < statsData.length && i < cached.length; i++) {
          statsData[i].addAll(Map<String, dynamic>.from(cached[i]));
        }
      });
    }
  }

  void _cacheStats() async {
    var box = await Hive.openBox('dashboard_stats');
    await box.put('statsData', statsData);
  }

  StreamSubscription? _orderSub;
  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  void _listenToOrderStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _orderSub?.cancel();
    _orderSub = FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .snapshots()
        .listen((querySnapshot) {
          fetchAndSetVendorOrderStats(querySnapshot: querySnapshot);
        });
  }

  void _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: customDateRange,
    );
    if (picked != null) {
      setState(() {
        customDateRange = picked;
        selectedFilter = -1; // Use -1 for custom
        customStatsData = {
          'totalOrders': 0,
          'totalSale': '₹0',
          'totalProducts': 0,
          'totalOrdersChange': 0.0,
          'totalSaleChange': 0.0,
          'totalProductsChange': 0.0,
          'totalOrdersUp': false,
          'totalSaleUp': false,
          'totalProductsUp': false,
          'pendingOrders': 0,
          'shippedOrders': 0,
          'deliveredOrders': 0,
        };
      });
      fetchAndSetVendorOrderStats();
    }
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

  Future<void> _calculateTrends(
    int currentOrders,
    double currentSales,
    QuerySnapshot querySnapshot,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Calculate previous period dates
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime prevMinDate, prevMaxDate;
    int daysBack = 0;

    if (selectedFilter == 0) {
      daysBack = 1; // Yesterday
      prevMinDate = today.subtract(const Duration(days: 2));
      prevMaxDate = today.subtract(const Duration(days: 1));
    } else if (selectedFilter == 1) {
      daysBack = 7; // Previous 7 days
      prevMinDate = today.subtract(const Duration(days: 14));
      prevMaxDate = today.subtract(const Duration(days: 7));
    } else if (selectedFilter == 2) {
      daysBack = 30; // Previous 30 days
      prevMinDate = today.subtract(const Duration(days: 60));
      prevMaxDate = today.subtract(const Duration(days: 30));
    } else if (selectedFilter == 3) {
      daysBack = 90; // Previous 90 days
      prevMinDate = today.subtract(const Duration(days: 180));
      prevMaxDate = today.subtract(const Duration(days: 90));
    } else {
      return; // Skip trend calculation for custom date range
    }

    // Get previous period data
    final prevSnapshot = await FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .get();

    int prevOrders = 0;
    double prevSales = 0.0;
    List<String> prevDeliveredProductIds = [];
    List<DocumentSnapshot> prevDeliveredDocs = [];

    for (var doc in prevSnapshot.docs) {
      final status = doc['status']?.toString().toLowerCase();
      DateTime? orderDate;
      final data = doc.data();
      final mapData = (data is Map<String, dynamic>) ? data : null;
      final orderDateRaw = (mapData != null) ? mapData['order_date'] : null;

      if (orderDateRaw != null) {
        if (orderDateRaw is Timestamp) {
          orderDate = orderDateRaw.toDate().toLocal();
        } else if (orderDateRaw is String) {
          try {
            orderDate = DateTime.parse(orderDateRaw).toLocal();
          } catch (_) {}
        }
      }

      bool inPrevRange = false;
      if (orderDate != null) {
        inPrevRange =
            !orderDate.isBefore(prevMinDate) && !orderDate.isAfter(prevMaxDate);
      }

      if (inPrevRange) {
        prevOrders++;
        if (status == 'delivered' || status == 'completed') {
          final productUidRaw = (mapData != null)
              ? mapData['product_uid']
              : null;
          if (productUidRaw != null && productUidRaw.toString().isNotEmpty) {
            prevDeliveredProductIds.add(productUidRaw.toString());
            prevDeliveredDocs.add(doc);
          }
        }
      }
    }

    // Calculate previous sales amount (similar to current sales calculation)
    Map<String, double> prevProductPriceMap = {};
    const int chunkSize = 10;
    for (int i = 0; i < prevDeliveredProductIds.length; i += chunkSize) {
      final chunk = prevDeliveredProductIds.skip(i).take(chunkSize).toList();
      if (chunk.isEmpty) continue;
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var prodDoc in productsSnapshot.docs) {
        final priceRaw = prodDoc['discount_price'];
        double price = 0.0;
        if (priceRaw is int) {
          price = priceRaw.toDouble();
        } else if (priceRaw is double) {
          price = priceRaw;
        } else if (priceRaw is String) {
          price = double.tryParse(priceRaw) ?? 0.0;
        }
        prevProductPriceMap[prodDoc.id] = price;
      }
    }

    for (int i = 0; i < prevDeliveredDocs.length; i++) {
      final doc = prevDeliveredDocs[i];
      int quantity = 1;
      final data = doc.data();
      String? localProductUid;
      if (data != null && data is Map) {
        final qtyRaw = data['quantity'];
        if (qtyRaw != null) {
          if (qtyRaw is int) {
            quantity = qtyRaw;
          } else if (qtyRaw is double) {
            quantity = qtyRaw.toInt();
          } else if (qtyRaw is String) {
            quantity = int.tryParse(qtyRaw) ?? 1;
          }
        }
        final productUidRaw = data['product_uid'];
        if (productUidRaw != null) localProductUid = productUidRaw.toString();
      }
      if (localProductUid != null &&
          prevProductPriceMap.containsKey(localProductUid)) {
        final price = prevProductPriceMap[localProductUid] ?? 0.0;
        prevSales += price * quantity;
      }
    }

    // Calculate percentage changes
    double ordersChange = 0.0;
    double salesChange = 0.0;
    bool ordersUp = false;
    bool salesUp = false;

    if (prevOrders > 0) {
      ordersChange = (currentOrders - prevOrders) / prevOrders;
      ordersUp = ordersChange > 0;
    } else if (currentOrders > 0) {
      ordersChange = 1.0; // 100% increase from 0
      ordersUp = true;
    }

    if (prevSales > 0) {
      salesChange = (currentSales - prevSales) / prevSales;
      salesUp = salesChange > 0;
    } else if (currentSales > 0) {
      salesChange = 1.0; // 100% increase from 0
      salesUp = true;
    }

    // Update the trend data
    setState(() {
      statsData[selectedFilter]['totalOrdersChange'] = ordersChange.abs();
      statsData[selectedFilter]['totalOrdersUp'] = ordersUp;
      statsData[selectedFilter]['totalSaleChange'] = salesChange.abs();
      statsData[selectedFilter]['totalSaleUp'] = salesUp;

      // For products, we'll show a sample trend since it doesn't change often
      statsData[selectedFilter]['totalProductsChange'] = 0.05; // 5% sample
      statsData[selectedFilter]['totalProductsUp'] = true;
    });
  }

  Future<void> fetchAndSetVendorOrderStats({
    QuerySnapshot? querySnapshot,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Use provided snapshot (from real-time) or fetch if null (for manual refresh)
    querySnapshot ??= await FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .get();

    int totalOrders = 0;
    int pendingOrders = 0;
    int shippedOrders = 0;
    int deliveredOrders = 0;
    double deliveredSaleAmount = 0.0;

    // To avoid multiple Firestore calls, collect productIds to fetch in batch
    List<String> deliveredProductIds = [];
    List<DocumentSnapshot> deliveredDocs = [];

    // Date filter setup
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime minDate, maxDate;
    if (selectedFilter == -1 && customDateRange != null) {
      minDate = customDateRange!.start;
      maxDate = customDateRange!.end.add(
        const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
      );
    } else {
      int daysBack = 0;
      if (selectedFilter == 0) {
        daysBack = 1; // Today
      } else if (selectedFilter == 1) {
        daysBack = 7;
      } else if (selectedFilter == 2) {
        daysBack = 30;
      } else if (selectedFilter == 3) {
        daysBack = 90;
      }
      minDate = today.subtract(Duration(days: daysBack - 1));
      maxDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    }

    for (var doc in querySnapshot.docs) {
      final status = doc['status']?.toString().toLowerCase();
      // Parse order_date
      DateTime? orderDate;
      final data = doc.data();
      final mapData = (data is Map<String, dynamic>) ? data : null;
      final orderDateRaw = (mapData != null) ? mapData['order_date'] : null;
      if (orderDateRaw != null) {
        if (orderDateRaw is Timestamp) {
          orderDate = orderDateRaw.toDate().toLocal();
        } else if (orderDateRaw is String) {
          try {
            orderDate = DateTime.parse(orderDateRaw).toLocal();
          } catch (_) {}
        }
      }
      // Only include if orderDate is within range
      bool inRange = false;
      if (orderDate != null) {
        if (selectedFilter == 0) {
          // Today: match calendar day
          inRange =
              orderDate.year == today.year &&
              orderDate.month == today.month &&
              orderDate.day == today.day;
        } else {
          // Other: minDate (00:00:00) <= orderDate <= maxDate (23:59:59.999)
          inRange = !orderDate.isBefore(minDate) && !orderDate.isAfter(maxDate);
        }
      }
      if (inRange) {
        totalOrders++;
        if (status == 'pending') {
          pendingOrders++;
        } else if (status == 'shipped') {
          shippedOrders++;
        } else if (status == 'delivered' || status == 'completed') {
          deliveredOrders++;
          // Fetch product_uid from doc.data() with null check
          final productUidRaw = (mapData != null)
              ? mapData['product_uid']
              : null;
          if (productUidRaw != null && productUidRaw.toString().isNotEmpty) {
            deliveredProductIds.add(productUidRaw.toString());
            deliveredDocs.add(doc);
          }
        }
      }
    }

    // Fetch product prices in batch (Firestore does not support 'in' queries for more than 10 items, so chunk if needed)
    Map<String, double> productPriceMap = {};
    const int chunkSize = 10;
    for (int i = 0; i < deliveredProductIds.length; i += chunkSize) {
      final chunk = deliveredProductIds.skip(i).take(chunkSize).toList();
      if (chunk.isEmpty) continue;
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var prodDoc in productsSnapshot.docs) {
        // Use discount_price if available, else 0
        final priceRaw = prodDoc['discount_price'];
        double price = 0.0;
        if (priceRaw is int) {
          price = priceRaw.toDouble();
        } else if (priceRaw is double) {
          price = priceRaw;
        } else if (priceRaw is String) {
          price = double.tryParse(priceRaw) ?? 0.0;
        }
        productPriceMap[prodDoc.id] = price;
      }
    }

    // Sum up delivered sale amount using productPriceMap
    for (int i = 0; i < deliveredDocs.length; i++) {
      final doc = deliveredDocs[i];
      int quantity = 1;
      final data = doc.data();
      String? localProductUid;
      if (data != null && data is Map) {
        final qtyRaw = data['quantity'];
        if (qtyRaw != null) {
          if (qtyRaw is int) {
            quantity = qtyRaw;
          } else if (qtyRaw is double) {
            quantity = qtyRaw.toInt();
          } else if (qtyRaw is String) {
            quantity = int.tryParse(qtyRaw) ?? 1;
          }
        }
        final productUidRaw = data['product_uid'];
        if (productUidRaw != null) localProductUid = productUidRaw.toString();
      }
      if (localProductUid != null &&
          productPriceMap.containsKey(localProductUid)) {
        final price = productPriceMap[localProductUid] ?? 0.0;
        final subtotal = price * quantity;
        deliveredSaleAmount += subtotal;
      }
    }

    // Calculate trends by comparing with previous period
    await _calculateTrends(totalOrders, deliveredSaleAmount, querySnapshot);

    if (!mounted) return;
    setState(() {
      if (selectedFilter == -1 && customStatsData != null) {
        customStatsData!['totalOrders'] = totalOrders;
        customStatsData!['pendingOrders'] = pendingOrders;
        customStatsData!['shippedOrders'] = shippedOrders;
        customStatsData!['deliveredOrders'] = deliveredOrders;
        customStatsData!['totalSale'] =
            '₹${deliveredSaleAmount.toStringAsFixed(0)}';
        // For custom date range, we'll set some sample trends
        customStatsData!['totalOrdersChange'] = 0.1; // 10% sample
        customStatsData!['totalOrdersUp'] = true;
        customStatsData!['totalSaleChange'] = 0.08; // 8% sample
        customStatsData!['totalSaleUp'] = false;
      } else {
        // Update the current period data
        statsData[selectedFilter]['totalOrders'] = totalOrders;
        statsData[selectedFilter]['pendingOrders'] = pendingOrders;
        statsData[selectedFilter]['shippedOrders'] = shippedOrders;
        statsData[selectedFilter]['deliveredOrders'] = deliveredOrders;
        statsData[selectedFilter]['totalSale'] =
            '₹${deliveredSaleAmount.toStringAsFixed(0)}';
        _cacheStats();
      }
    });
  }

  Widget buildFilterButton(String label, int index) {
    final bool selected = selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = index;
        });
        fetchAndSetVendorOrderStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFf1f5f9) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFe2e8f0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : const Color(0xFF64748b),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget buildStatBox({
    required String title,
    required String value,
    required double percent,
    required bool isUp,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title at the top
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748b),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Main value
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e293b),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Trend indicator and subtitle
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? const Color(0xFF10b981) : const Color(0xFFef4444),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                "${(percent.abs() * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: isUp
                      ? const Color(0xFF10b981)
                      : const Color(0xFFef4444),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildOrderProgress({
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
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        (selectedFilter == -1 && customStatsData != null)
        ? customStatsData!
        : statsData[selectedFilter];
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

    String getSubtitle(int filter) {
      if (filter == -1 && customDateRange != null) {
        return "Custom: ${customDateRange!.start.month}/${customDateRange!.start.day} - ${customDateRange!.end.month}/${customDateRange!.end.day}";
      }
      switch (filter) {
        case 0:
          return "vs yesterday";
        case 1:
          return "vs last 7 days";
        case 2:
          return "vs last 30 days";
        case 3:
          return "vs last 90 days";
        default:
          return "";
      }
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
                        buildFilterButton("Today", 0),
                        const SizedBox(width: 8),
                        buildFilterButton("7 Days", 1),
                        const SizedBox(width: 8),
                        buildFilterButton("30 Days", 2),
                        const SizedBox(width: 8),
                        buildFilterButton("90 Days", 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickCustomDateRange,
                  child: const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Updated stat cards design to match the image
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: buildStatBox(
                        title: "Total Orders",
                        value: totalOrders.toString(),
                        percent: data['totalOrdersChange'],
                        isUp: data['totalOrdersUp'],
                        subtitle: getSubtitle(selectedFilter),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildStatBox(
                        title: "Total Sale",
                        value: totalSale,
                        percent: data['totalSaleChange'],
                        isUp: data['totalSaleUp'],
                        subtitle: getSubtitle(selectedFilter),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildStatBox(
                        title: "Total Products",
                        value: totalProducts.toString(),
                        percent: data['totalProductsChange'],
                        isUp: data['totalProductsUp'],
                        subtitle: getSubtitle(selectedFilter),
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
                border: Border.all(color: const Color(0xFFe0e7ff)),
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
                  buildOrderProgress(
                    label: "Pending Orders",
                    percent: safePercent(pendingOrders, totalOrders),
                    value: pendingOrders,
                    total: totalOrders,
                    color: const Color(0xFFfbbf24),
                  ),
                  const SizedBox(height: 24),
                  buildOrderProgress(
                    label: "Shipped Orders",
                    percent: safePercent(shippedOrders, totalOrders),
                    value: shippedOrders,
                    total: totalOrders,
                    color: const Color(0xFFa78bfa),
                  ),
                  const SizedBox(height: 24),
                  buildOrderProgress(
                    label: "Delivered Orders",
                    percent: safePercent(deliveredOrders, totalOrders),
                    value: deliveredOrders,
                    total: totalOrders,
                    color: const Color(0xFF34d399),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
