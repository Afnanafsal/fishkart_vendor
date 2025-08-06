import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fishkart_vendor/screens/add_product/add_product_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fishkart_vendor/services/database/product_database_helper.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:fishkart_vendor/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';

class ManageProductsScreen extends StatelessWidget {
  static String routeName = "/manage_products";

  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    label: const Text(
                      'Add product',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Fishes',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Swipe LEFT to edit, swipe Right to delete',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: ProductsList()),
          ],
        ),
      ),
    );
  }
}

class ProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(ProductDatabaseHelper.PRODUCTS_COLLECTION_NAME)
          .where(
            'vendorId',
            isEqualTo: AuthentificationService().currentUser.uid,
          )
          .snapshots(),
      builder: (context, snapshot) {
        final screenHeight = 1.sh;
        final reservedHeight = 16.h + 16.h + 56.h + 80.h;
        final cardMargin = 10.h;
        final totalMargins = cardMargin * 5;
        final itemHeight = (screenHeight - reservedHeight - totalMargins) / 5.5;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListTile(contentPadding: EdgeInsets.all(16.w)),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 100,
                  color: kPrimaryColor,
                ),
                SizedBox(height: 20),
                Text(
                  'No products yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Start by adding your first product'),
              ],
            ),
          );
        }
        final products = snapshot.data!.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                return Product.fromMap(data, id: doc.id);
              } catch (e) {
                print('Error parsing product \\${doc.id}: $e');
                return null;
              }
            })
            .where((product) => product != null)
            .cast<Product>()
            .toList();
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 100, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Error loading products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('There was an error loading your products'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              height: itemHeight,
              child: Dismissible(
                key: Key(product.id),
                background: Container(),
                secondaryBackground: Container(),
                confirmDismiss: (direction) async {
                  // ...existing code...
                  if (direction == DismissDirection.endToStart) {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Product'),
                        content: Text(
                          'Are you sure you want to delete this product?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ProductDatabaseHelper().deleteUserProduct(
                          product.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Product deleted successfully'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete product')),
                        );
                      }
                    }
                    return confirm == true;
                  } else if (direction == DismissDirection.startToEnd) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddProductScreen(productToEdit: product),
                      ),
                    );
                    return false;
                  }
                  return false;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          bottomLeft: Radius.circular(20.r),
                        ),
                        child: Builder(
                          builder: (context) {
                            if (product.images == null ||
                                product.images!.isEmpty) {
                              return Container(
                                width: itemHeight,
                                height: itemHeight,
                                color: kPrimaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.black38,
                                  size: 32.sp,
                                ),
                              );
                            }
                            try {
                              final base64Image = product.images![0];
                              final imageData =
                                  base64Image.startsWith('data:image')
                                  ? base64Image.split(',')[1]
                                  : base64Image;
                              return Image.memory(
                                base64Decode(imageData),
                                width: itemHeight,
                                height: itemHeight,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: itemHeight,
                                    height: itemHeight,
                                    color: kPrimaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.black38,
                                      size: 32.sp,
                                    ),
                                  );
                                },
                              );
                            } catch (e) {
                              return Container(
                                width: itemHeight,
                                height: itemHeight,
                                color: kPrimaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.error,
                                  color: Colors.black38,
                                  size: 32.sp,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: 12.w,
                            top: 16.h,
                            bottom: 16.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.title ?? 'Untitled Product',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Net weight: ${product.variant ?? '-'}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12.sp,
                                  color: Color(0xFF7B7B7B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Text(
                                    '₹${product.discountPrice ?? product.originalPrice ?? 0}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (product.discountPrice != null &&
                                      product.originalPrice != null &&
                                      product.discountPrice !=
                                          product.originalPrice)
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: Text(
                                        '₹${product.originalPrice}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13.sp,
                                          color: Color(0xFFBDBDBD),
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 18.w),
                        child: CustomSwitch(
                          value: product.isAvailable ?? true,
                          onChanged: (value) async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection(
                                    ProductDatabaseHelper
                                        .PRODUCTS_COLLECTION_NAME,
                                  )
                                  .doc(product.id)
                                  .update({'isAvailable': value});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Product is now available'
                                        : 'Product is now unavailable',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update availability',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
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
    // ...existing code...
  }
}

// Custom Switch widget for exact UI
class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const CustomSwitch({Key? key, required this.value, required this.onChanged})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: value
              ? null
              : Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? Colors.white : const Color(0xFFBDBDBD),
              shape: BoxShape.circle,
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
