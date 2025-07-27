import 'package:fishkart_vendor/models/Product.dart';
import 'package:flutter/material.dart';

import 'package:fishkart_vendor/screens/edit_product/edit_product_screen.dart';
import 'package:fishkart_vendor/screens/manage_products/manage_products_screen.dart';
import 'components/custom_bottom_nav_bar.dart';
import '../profile/profile_screen.dart';
import 'components/home_header.dart';
import 'components/vendor_dashboard_summary.dart';
import 'components/recent_orders_list.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "/home";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    // Home tab with HomeHeader and dashboard summary
    SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(),
          VendorDashboardSummary(),
        ],
      ),
    ),
    // Placeholder, will be replaced by navigation to EditProductScreen
    SizedBox.shrink(),
    ManageProductsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Create a blank Product for adding a new product
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
