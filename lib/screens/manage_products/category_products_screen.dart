import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({Key? key}) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedCategory = productCategories[selectedIndex]['key'] as String;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.w, top: 20.h),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 24.sp,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                splashRadius: 22.r,
                tooltip: 'Back',
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Text(
                    'Your products',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22.sp,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'View all of your products below',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    height: 180.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 0),
                      itemCount: productCategories.length,
                      separatorBuilder: (context, i) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        final cat = productCategories[index];
                        final selected = index == selectedIndex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            width: 105.w,
                            height: 160.h,
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 95.w,
                              height: 148.h,
                              margin: EdgeInsets.only(top: 16.h, bottom: 16.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(70.r),
                                border: selected
                                    ? Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1.w,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 0,
                                      ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.14),
                                          blurRadius: 10.r,
                                          offset: Offset(0, 6.h),
                                          spreadRadius: 1.r,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8.r,
                                          offset: Offset(0, 2.h),
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12.h),
                                  Container(
                                    width: 70.w,
                                    height: 60.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.10,
                                                ),
                                                blurRadius: 8.r,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        cat['icon'],
                                        width: 70.w,
                                        height: 70.w,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  SizedBox(height: 12.h),
                                  SizedBox(
                                    width: 85.w,
                                    child: Text(
                                      cat['title'],
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                        fontFamily: 'Poppins',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.only(left: 24.w),
              child: Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('product_type', isEqualTo: selectedCategory)
                      .where(
                        'vendorId',
                        isEqualTo: AuthentificationService().currentUser.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }
                    final products = snapshot.data!.docs
                        .map((doc) {
                          try {
                            return Product.fromMap(
                              doc.data() as Map<String, dynamic>,
                              id: doc.id,
                            );
                          } catch (e) {
                            return null;
                          }
                        })
                        .where((p) => p != null)
                        .cast<Product>()
                        .toList();
                    return ListView.separated(
                      itemCount: products.length > 4 ? 4 : products.length,
                      separatorBuilder: (context, idx) =>
                          SizedBox(height: 16.h),
                      itemBuilder: (context, idx) {
                        final product = products[idx];
                        return _buildProductCard(product);
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

  int selectedIndex = 0;

  final List<Map<String, dynamic>> productCategories = [
    {
      'icon': "assets/icons/mackerel.png",
      'title': "Freshwater",
      'key': 'Freshwater',
    },
    {
      'icon': "assets/icons/Pomfret.png",
      'title': "Saltwater",
      'key': 'Saltwater',
    },
    {
      'icon': "assets/icons/Lobster.png",
      'title': "Shellfish",
      'key': 'Shellfish',
    },
    {
      'icon': "assets/icons/salmon.png",
      'title': "Exotic Fish",
      'key': 'Exotic',
    },
    {
      'icon': "assets/icons/Anchovies.png",
      'title': "Dried Fish",
      'key': 'Dried',
    },
    {'icon': "assets/icons/canned.png", 'title': "Others", 'key': 'Others'},
  ];

  Widget _buildProductCard(Product product) {
    final isAvailable = product.isAvailable ?? true;
    Widget imageWidget;

    // Build image widget with proper scaling and positioning
    if (product.images != null && product.images!.isNotEmpty) {
      final img = product.images!.first;
      Widget imgChild;
      if (img.startsWith('data:image')) {
        try {
          final base64Str = img.split(',').last;
          imgChild = Image.memory(
            base64Decode(base64Str),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, size: 32, color: Colors.grey),
          );
        } catch (_) {
          imgChild = const Icon(Icons.image, size: 32, color: Colors.grey);
        }
      } else if (img.startsWith('http')) {
        imgChild = Image.network(
          img,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image, size: 32, color: Colors.grey),
        );
      } else if (img.length > 100) {
        try {
          imgChild = Image.memory(
            base64Decode(img),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, size: 32, color: Colors.grey),
          );
        } catch (_) {
          imgChild = const Icon(Icons.image, size: 32, color: Colors.grey);
        }
      } else {
        imgChild = Image.asset(
          img,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }

      imageWidget = Container(
        width: 120,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isAvailable ? Colors.transparent : Colors.grey.withOpacity(0.6),
                isAvailable ? BlendMode.multiply : BlendMode.saturation,
              ),
              child: imgChild,
            ),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        width: 120,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isAvailable
              ? const Color(0xFFE0E0E0)
              : const Color(0xFFE0E0E0).withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Icon(
          Icons.image,
          size: 32,
          color: isAvailable ? Colors.grey : Colors.grey.withOpacity(0.5),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.white : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                blurRadius: 8.r,
                color: Colors.black.withOpacity(isAvailable ? 0.06 : 0.03),
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          height: 120.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              imageWidget,
              SizedBox(width: 16.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 8.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: isAvailable
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          if (product.variant != null &&
                              product.variant!.isNotEmpty)
                            Text(
                              'Net weight: ${product.variant}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isAvailable
                                    ? const Color(0xFF8E8E93)
                                    : Colors.grey.shade500,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${product.discountPrice?.toStringAsFixed(2) ?? '--'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                    color: isAvailable
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (product.originalPrice != null &&
                                    product.originalPrice !=
                                        product.discountPrice)
                                  Text(
                                    '₹${product.originalPrice?.toStringAsFixed(2) ?? ''}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isAvailable
                                          ? const Color(0xFFB0B0B0)
                                          : Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(product.id)
                                  .update({'isAvailable': !isAvailable});
                              setState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48.w,
                              height: 26.h,
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFB0B0B0),
                                borderRadius: BorderRadius.circular(26.r),
                              ),
                              child: Align(
                                alignment: isAvailable
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.all(2.0.w),
                                  child: Container(
                                    width: 22.w,
                                    height: 22.w,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 2.r,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
