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
                    height: 170, 
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
                          child: Container(
                            width: 120,
                            height: 148, // Slightly reduced to avoid cutoff
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 110,
                              height:
                                  136, // Reduced height to fit inside parent
                              margin: const EdgeInsets.only(
                                top: 8,
                                bottom: 4,
                              ), // Less bottom margin to avoid cutoff
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(70),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            0.14,
                                          ), // Softer shadow
                                          blurRadius: 16, // Softer blur
                                          offset: const Offset(
                                            0,
                                            6,
                                          ), // Gentle offset
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.10,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
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
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.black,
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
    );
  }

  int selectedIndex = 0;

  final List<Map<String, dynamic>> productCategories = [
    {
      'icon': "assets/images/8k.jpg",
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

      // Scaled up image container with left positioning
      imageWidget = Container(
        width: 120, // Increased from 100
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: imgChild,
        ),
      );
    } else {
      imageWidget = Container(
        width: 120, // Increased from 100
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: const Icon(Icons.image, size: 32, color: Colors.grey),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ), // Adjusted margins
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          height: 120, // Increased height for better proportions
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image takes up more space and is positioned to the left
              imageWidget,
              const SizedBox(width: 16), // Increased spacing
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title and weight
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (product.variant != null &&
                              product.variant!.isNotEmpty)
                            Text(
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
                        ],
                      ),
                      // Price and toggle section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price section
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${product.discountPrice?.toStringAsFixed(2) ?? '--'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18, // Slightly larger
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (product.originalPrice != null &&
                                    product.originalPrice !=
                                        product.discountPrice)
                                  Text(
                                    '₹${product.originalPrice?.toStringAsFixed(2) ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB0B0B0),
                                      decoration: TextDecoration.lineThrough,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Custom toggle switch UI
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
                              width: 48, // Slightly larger
                              height: 26,
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFB0B0B0),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Align(
                                alignment: isAvailable
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 2,
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
