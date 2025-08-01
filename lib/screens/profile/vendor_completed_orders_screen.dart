import 'package:flutter/material.dart';
import 'vendor_completed_orders_list.dart';

class VendorCompletedOrdersScreen extends StatelessWidget {
  const VendorCompletedOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Color(0xFF10b981)),
            SizedBox(width: 8),
            Text(
              'Completed Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: VendorCompletedOrdersList(),
    );
  }
}
