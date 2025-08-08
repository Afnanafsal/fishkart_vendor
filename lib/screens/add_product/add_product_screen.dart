import 'dart:convert';
import 'package:flutter/material.dart';
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
                  margin: EdgeInsets.only(right: 8),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
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
                width: 80,
                height: 80,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Icon(Icons.add, color: Colors.black),
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
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kPrimaryColor),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProductTypeDropdown() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<ProductType>(
        value: _selectedType,
        decoration: InputDecoration(
          labelText: 'Product Type',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: ProductType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.toString().split('.').last),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedType = value!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Edit Product' : 'Add Product',
        ),
        centerTitle: true,
        leading: BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                SizedBox(height: 20),
                _buildTextField(
                  label: 'Product Name',
                  controller: _titleController,
                  hint: 'Product name',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                _buildTextField(
                  label: 'Quantity of the product (kg/gram)',
                  controller: _variantController,
                  hint: 'Net weight gms',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                _buildTextField(
                  label: 'Original Price',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? 'Enter valid price'
                      : null,
                ),
                _buildTextField(
                  label: 'Discounted Price',
                  controller: _discountPriceController,
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
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Enter valid stock'
                      : null,
                ),
                _buildProductTypeDropdown(),
                _buildTextField(
                  label: 'Sub Title',
                  controller: _highlightController,
                  hint: 'Boneless, Fresh etc.',
                ),
                _buildTextField(
                  label: 'Product Details',
                  controller: _descriptionController,
                  hint: 'Write about the product',
                  maxLines: 3,
                ),
                _buildTextField(
                  label: 'Seller name',
                  controller: TextEditingController(text: '[autofetch]'),
                  enabled: false,
                ),
                _buildTextField(
                  label: 'Location',
                  controller: _areaLocationController,
                  hint: 'Enter area/location',
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.productToEdit != null
                          ? 'Save Changes'
                          : 'Add Product',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
