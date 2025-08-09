import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fishkart_vendor/constants.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/services/database/product_database_helper.dart';
import 'package:fishkart_vendor/services/database/user_database_helper.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  List<String> _images = [];

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _stockController;
  late TextEditingController _areaLocationController;
  late TextEditingController _highlightController;
  late TextEditingController _variantController;

  ProductType _selectedType = ProductType.Others;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;
    _titleController = TextEditingController(text: product?.title ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: product?.originalPrice?.toString() ?? '',
    );
    _discountPriceController = TextEditingController(
      text: product?.discountPrice?.toString() ?? '',
    );
    _stockController = TextEditingController();
    _areaLocationController = TextEditingController(
      text: product?.areaLocation ?? '',
    );
    _highlightController = TextEditingController(
      text: product?.highlights ?? '',
    );
    _variantController = TextEditingController(text: product?.variant ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVendorAreaLocationIfAny();
    });

    if (product != null) {
      _images = List<String>.from(product.images ?? []);
      _selectedType = product.productType ?? ProductType.Others;
      ProductDatabaseHelper().getProductStockRemaining(product.id).then((
        stock,
      ) {
        if (mounted) {
          setState(() {
            _stockController.text = stock?.toString() ?? '';
          });
        }
      });
    }
  }

  Future<void> _fetchVendorAreaLocationIfAny() async {
    if (widget.productToEdit == null && _areaLocationController.text.isEmpty) {
      try {
        final areaLocation = await UserDatabaseHelper()
            .getCurrentUserAreaLocation();
        if (areaLocation != null) {
          setState(() {
            _areaLocationController.text = areaLocation;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _addImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maximum 3 images allowed')));
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        _images.add(base64Image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState?.validate() != true) return;

    try {
      final product = Product(
        widget.productToEdit?.id ?? '',
        images: _images,
        title: _titleController.text,
        description: _descriptionController.text,
        originalPrice: double.parse(_priceController.text),
        discountPrice: _discountPriceController.text.isNotEmpty
            ? double.parse(_discountPriceController.text)
            : null,
        productType: _selectedType,
        rating: widget.productToEdit?.rating ?? 0.0,
        areaLocation: _areaLocationController.text,
        highlights: _highlightController.text,
        variant: _variantController.text,
      );

      final stockValue = int.tryParse(_stockController.text) ?? 0;

      if (widget.productToEdit == null) {
        final productId = await ProductDatabaseHelper().addUsersProduct(
          product,
        );
        await ProductDatabaseHelper().addProductStockSubcollection(
          productId,
          stockValue,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product added successfully')));
      } else {
        await ProductDatabaseHelper().updateUsersProduct(product);
        await ProductDatabaseHelper().updateProductStockRemaining(
          product.id,
          stockValue,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product updated successfully')));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildImagePicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(_images.length, (index) {
            final img = _images[index];
            ImageProvider imageProvider;
            if (img.startsWith('data:image')) {
              imageProvider = MemoryImage(
                Uri.parse(img).data!.contentAsBytes(),
              );
            } else if (img.startsWith('http')) {
              imageProvider = NetworkImage(img);
            } else {
              try {
                imageProvider = MemoryImage(base64Decode(img));
              } catch (_) {
                imageProvider = const AssetImage(
                  'assets/images/placeholder.png',
                );
              }
            }

            return Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(right: 8.w),
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red, size: 20.sp),
                    onPressed: () => _removeImage(index),
                  ),
                ),
              ],
            );
          }),
          if (_images.length < 3)
            GestureDetector(
              onTap: _addImage,
              child: Container(
                width: 80.w,
                height: 80.w,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Icon(Icons.add, color: Colors.black, size: 24.sp),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 6.h),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: kPrimaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeDropdown() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Type',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 6.h),
          DropdownButtonFormField<ProductType>(
            value: _selectedType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: kPrimaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            items: ProductType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.toString().split('.').last,
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF1F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 28.h),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.back,
                      size: 24.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Card content
              Card(
                color: Colors.white.withOpacity(0.41),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      Text(
                        widget.productToEdit != null
                            ? 'Edit product'
                            : 'Add product',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImagePicker(),
                            SizedBox(height: 24.h),
                            _buildTextField(
                              label: 'Product name',
                              controller: _titleController,
                              hint: 'Product name',
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            _buildTextField(
                              label: 'Quantity of the product (kg/gram)',
                              controller: _variantController,
                              hint: 'Net weight gms',
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            _buildTextField(
                              label: 'Original price',
                              controller: _priceController,
                              hint: 'Original price',
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v == null || double.tryParse(v) == null
                                  ? 'Enter valid price'
                                  : null,
                            ),
                            _buildTextField(
                              label: 'Discounted price',
                              controller: _discountPriceController,
                              hint: 'Discounted price',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final original =
                                    double.tryParse(_priceController.text) ?? 0;
                                final discount = double.tryParse(v);
                                if (discount == null || discount >= original) {
                                  return 'Must be less than original price';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              label: 'Stock',
                              controller: _stockController,
                              hint: 'Stock',
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v == null || int.tryParse(v) == null
                                  ? 'Enter valid stock'
                                  : null,
                            ),
                            _buildProductTypeDropdown(),
                            _buildTextField(
                              label: 'Sub title',
                              controller: _highlightController,
                              hint: 'Boneless, Fresh etc.',
                            ),
                            _buildTextField(
                              label: 'Product Details',
                              controller: _descriptionController,
                              hint: 'About product and Product Details',
                              maxLines: 3,
                            ),
                            _buildTextField(
                              label: 'Seller name',
                              controller: TextEditingController(
                                text:
                                    AuthentificationService()
                                        .currentUser
                                        .displayName ??
                                    '',
                              ),
                              hint:
                                  AuthentificationService()
                                      .currentUser
                                      .displayName ??
                                  '[autofetch]',
                              enabled: false,
                            ),
                            FutureBuilder<String?>(
                              future: UserDatabaseHelper()
                                  .getCurrentUserAreaLocation(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildTextField(
                                    label: 'Location',
                                    controller: _areaLocationController,
                                    hint: 'Fetching...',
                                    enabled: false,
                                  );
                                }
                                if (snapshot.hasError) {
                                  return _buildTextField(
                                    label: 'Location',
                                    controller: _areaLocationController,
                                    hint: 'Error fetching location',
                                    enabled: false,
                                  );
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  _areaLocationController.text = snapshot.data!;
                                }
                                return _buildTextField(
                                  label: 'Location',
                                  controller: _areaLocationController,
                                  hint: '[autofetch]',
                                );
                              },
                            ),

                            SizedBox(height: 24.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(vertical: 24.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  widget.productToEdit != null
                                      ? 'Save Changes'
                                      : 'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
