import 'package:fishkart_vendor/models/Product.dart';
import 'package:flutter/material.dart';

import 'package:fishkart_vendor/screens/edit_product/edit_product_screen.dart';
import 'package:fishkart_vendor/screens/manage_products/manage_products_screen.dart';
import 'components/custom_bottom_nav_bar.dart';
import '../profile/profile_screen.dart';
import 'components/body.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart_vendor/screens/inbox/notification_overlay.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  static const String routeName = "/home";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeBody(),
    SizedBox.shrink(),
    ManageProductsScreen(),
    ProfileScreen(),
  ];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _orderListener;
  Map<String, dynamic>? _latestOrderData;
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();
    _listenForPendingOrders();
  }

  void _listenForPendingOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _orderListener = FirebaseFirestore.instance
        .collectionGroup('ordered_products')
        .where('vendor_id', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('order_date', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final latestOrder = snapshot.docs.first.data();
            if (_latestOrderData == null ||
                _latestOrderData!['order_id'] != latestOrder['order_id']) {
              _latestOrderData = latestOrder;
              _showOrderNotification(latestOrder);
            }
          }
        });
  }

  void _showOrderNotification(Map<String, dynamic> orderData) {
    if (!_notificationShown) {
      _notificationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationOverlayManager.showOrderNotification(
          context: context,
          orderData: orderData,
          onTap: () {
            Navigator.of(context).pushNamed('/inbox');
            NotificationOverlayManager.hideNotification(
              context as OverlayEntry,
            );
          },
        );
        Future.delayed(const Duration(seconds: 5), () {
          _notificationShown = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _orderListener?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      final newProduct = Product('');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProductScreen(productToEdit: newProduct),
        ),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
