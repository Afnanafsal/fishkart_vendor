import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'dart:convert';

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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Your products',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View all of your products below',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 156,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      itemCount: productCategories.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(width: 24),
                      itemBuilder: (context, index) {
                        final cat = productCategories[index];
                        final selected = index == selectedIndex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: 110,
                            height: 140,
                            margin: const EdgeInsets.symmetric(vertical: 0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(70),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1.2,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      cat['icon'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    cat['title'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: const Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      return Center(child: Text('Error: \\${snapshot.error}'));
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
                          const SizedBox(height: 16),
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
      // bottomNavigationBar removed
    );
  }

  int selectedIndex = 0;

  final List<Map<String, dynamic>> productCategories = [
    {
      'icon': "assets/images/8k.jpg",
      'title': "Freshwater Fish",
      'key': 'Freshwater',
    },
    {
      'icon': "assets/icons/Pomfret.png",
      'title': "Saltwater Fish",
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
  // Widget build and all widget code is inside the build method below
  Widget _buildProductCard(Product product) {
    final isAvailable = product.isAvailable ?? true;
    Widget imageWidget;
    // Make the image fill the card height (top and bottom flush)
    const double imageWidth = 110;
    if (product.images != null && product.images!.isNotEmpty) {
      final img = product.images!.first;
      if (img.startsWith('data:image')) {
        try {
          final base64Str = img.split(',').last;
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              base64Decode(base64Str),
              width: imageWidth,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFE0E0E0),
                width: imageWidth,
                height: double.infinity,
                child: const Icon(Icons.image, size: 32, color: Colors.grey),
              ),
            ),
          );
        } catch (_) {
          imageWidget = Container(
            width: imageWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.image, size: 32, color: Colors.grey),
          );
        }
      } else if (img.startsWith('http')) {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            img,
            width: imageWidth,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFE0E0E0),
              width: imageWidth,
              height: double.infinity,
              child: const Icon(Icons.image, size: 32, color: Colors.grey),
            ),
          ),
        );
      } else if (img.length > 100) {
        try {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              base64Decode(img),
              width: imageWidth,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFE0E0E0),
                width: imageWidth,
                height: double.infinity,
                child: const Icon(Icons.image, size: 32, color: Colors.grey),
              ),
            ),
          );
        } catch (_) {
          imageWidget = Container(
            width: imageWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.image, size: 32, color: Colors.grey),
          );
        }
      } else {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            img,
            width: imageWidth,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      imageWidget = Container(
        width: imageWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.image, size: 32, color: Colors.grey),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image flush to the left, fill height, round only left corners
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: SizedBox(width: imageWidth, child: imageWidget),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.title ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.variant != null && product.variant!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Net weight: ${product.variant}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '₹${product.discountPrice?.toStringAsFixed(2) ?? '--'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (product.originalPrice != null &&
                          product.originalPrice != product.discountPrice)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '₹${product.originalPrice?.toStringAsFixed(2) ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB0B0B0),
                              decoration: TextDecoration.lineThrough,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
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
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: SizedBox(
              width: 52,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isAvailable)
                    GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(product.id)
                            .update({'isAvailable': true});
                        setState(() {});
                      },
                      child: Container(
                        width: 52,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: const Color(0xFF646161),
                            width: 2,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF646161),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isAvailable)
                    GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(product.id)
                            .update({'isAvailable': false});
                        setState(() {});
                      },
                      child: Container(
                        width: 52,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Transform.scale(
                              scale: 0.9,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Custom Switch theme for outline effect when off
          // To get a true outline, wrap Switch in Theme and override SwitchThemeData
        ],
      ),
    );
  }
}
