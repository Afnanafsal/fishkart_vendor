import 'dart:io';
import 'dart:typed_data';
import 'package:fishkart_vendor/services/database/user_database_helper.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fishkart_vendor/components/async_progress_dialog.dart';
import 'package:fishkart_vendor/components/default_button.dart';
import 'package:fishkart_vendor/exceptions/local_files_handling/local_file_handling_exception.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:fishkart_vendor/screens/edit_product/provider_models/ProductDetails.dart';
import 'package:fishkart_vendor/services/database/product_database_helper.dart';
import 'package:fishkart_vendor/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart_vendor/services/local_files_access/local_files_access_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../size_config.dart';

class EditProductForm extends ConsumerStatefulWidget {
  final Product product;
  const EditProductForm({Key? key, required this.product}) : super(key: key);

  @override
  ConsumerState<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends ConsumerState<EditProductForm> {
  final _basicDetailsFormKey = GlobalKey<FormState>();
  final _describeProductFormKey = GlobalKey<FormState>();

  final TextEditingController titleFieldController = TextEditingController();
  final TextEditingController variantFieldController = TextEditingController();
  final TextEditingController discountPriceFieldController =
      TextEditingController();
  final TextEditingController originalPriceFieldController =
      TextEditingController();
  final TextEditingController highlightsFieldController =
      TextEditingController();
  final TextEditingController desciptionFieldController =
      TextEditingController();
  final TextEditingController sellerFieldController = TextEditingController();
  final TextEditingController stockFieldController = TextEditingController();
  final TextEditingController areaLocationFieldController =
      TextEditingController();

  bool newProduct = true;
  late Product product;

  @override
  void dispose() {
    titleFieldController.dispose();
    variantFieldController.dispose();
    discountPriceFieldController.dispose();
    originalPriceFieldController.dispose();
    highlightsFieldController.dispose();
    desciptionFieldController.dispose();
    sellerFieldController.dispose();
    stockFieldController.dispose();
    areaLocationFieldController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    product = widget.product;
    newProduct = product.id.isEmpty;
    if (!newProduct) {
      ProductDatabaseHelper().getProductWithID(product.id).then((freshProduct) {
        if (freshProduct != null) {
          setState(() {
            product = freshProduct;
            titleFieldController.text = product.title ?? '';
            variantFieldController.text = product.variant ?? '';
            originalPriceFieldController.text = product.originalPrice?.toString() ?? '';
            discountPriceFieldController.text = product.discountPrice?.toString() ?? '';
            highlightsFieldController.text = product.highlights ?? '';
            desciptionFieldController.text = product.description ?? '';
            sellerFieldController.text = product.seller ?? '';
            stockFieldController.text = (product.stock?.toString() ?? '');
            areaLocationFieldController.text = product.areaLocation ?? '';

            // Set product type in provider
            if (product.productType != null) {
              final productDetailsNotifier = ref.read(
                productDetailsProvider.notifier,
              );
              productDetailsNotifier.setInitialProductType(product.productType!);
            }

            // Set images in provider
            if (product.images != null && product.images!.isNotEmpty) {
              final productDetailsNotifier = ref.read(
                productDetailsProvider.notifier,
              );
              productDetailsNotifier.setInitialSelectedImages(
                product.images!
                    .map(
                      (img) => CustomImage(imgType: ImageType.network, path: img),
                    )
                    .toList(),
              );
            }
          });
        }
      });
    }
    // For new product, fetch vendor's area location as default (only if areaLocation is empty)
    if ((product.areaLocation == null || product.areaLocation!.isEmpty) &&
        areaLocationFieldController.text.isEmpty) {
      Future.microtask(() async {
        final areaLocation = await UserDatabaseHelper().getCurrentUserAreaLocation();
        if (areaLocation != null && areaLocationFieldController.text.isEmpty) {
          setState(() {
            areaLocationFieldController.text = areaLocation;
          });
        }
      });
    }
    // Note: ProductDetails provider is now initialized in EditProductScreen
  }

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        buildBasicDetailsTile(context),
        SizedBox(height: getProportionateScreenHeight(10)),
        buildAreaLocationField(context),
        SizedBox(height: getProportionateScreenHeight(10)),
        buildDescribeProductTile(context),
        SizedBox(height: getProportionateScreenHeight(10)),
        buildUploadImagesTile(context),
        SizedBox(height: getProportionateScreenHeight(20)),
        buildProductTypeDropdown(),
        SizedBox(height: getProportionateScreenHeight(50)),
        DefaultButton(
          text: "Save Product",
          press: () {
            saveProductButtonCallback(context);
          },
        ),
        SizedBox(height: getProportionateScreenHeight(10)),
      ],
    );
    // No longer set areaLocationFieldController from vendorLocation
    return column;
  }

  Widget buildBasicDetailsTile(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Form(
          key: _basicDetailsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shop, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  Text(
                    "Basic Details",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              buildTitleField(),
              SizedBox(height: getProportionateScreenHeight(16)),
              buildVariantField(),
              SizedBox(height: getProportionateScreenHeight(16)),
              buildOriginalPriceField(),
              SizedBox(height: getProportionateScreenHeight(16)),
              buildDiscountPriceField(),
              SizedBox(height: getProportionateScreenHeight(16)),
              buildSellerField(),
              SizedBox(height: getProportionateScreenHeight(16)),
              buildStockField(),
            ],
          ),
        ),
      ),
    );
  }

  bool validateBasicDetailsForm() {
    if (_basicDetailsFormKey.currentState!.validate()) {
      _basicDetailsFormKey.currentState!.save();
      product.title = titleFieldController.text;
      product.variant = variantFieldController.text;
      product.originalPrice = double.parse(originalPriceFieldController.text);
      product.discountPrice = double.parse(discountPriceFieldController.text);
      product.seller = sellerFieldController.text;
      product.stock = int.tryParse(stockFieldController.text) ?? 0;
      product.areaLocation = areaLocationFieldController.text;
      return true;
    }
    return false;
  }

  Widget buildStockField() {
    return TextFormField(
      controller: stockFieldController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "e.g., 100",
        labelText: "Stock",
        prefixIcon: Icon(Icons.inventory),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (stockFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (int.tryParse(stockFieldController.text) == null) {
          return "Enter a valid number";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildDescribeProductTile(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Form(
          key: _describeProductFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Describe Product",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              buildHighlightsField(),
              SizedBox(height: getProportionateScreenHeight(16)),
              buildDescriptionField(),
            ],
          ),
        ),
      ),
    );
  }

  bool validateDescribeProductForm() {
    if (_describeProductFormKey.currentState!.validate()) {
      _describeProductFormKey.currentState!.save();
      product.highlights = highlightsFieldController.text;
      product.description = desciptionFieldController.text;
      return true;
    }
    return false;
  }

  Widget buildProductTypeDropdown() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Consumer(
          builder: (context, ref, child) {
            final productDetailsState = ref.watch(productDetailsProvider);
            final productDetailsNotifier = ref.read(
              productDetailsProvider.notifier,
            );
            return Row(
              children: [
                Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<ProductType>(
                    value: productDetailsState.productType,
                    items: ProductType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(EnumToString.convertToString(e)),
                          ),
                        )
                        .toList(),
                    decoration: InputDecoration(
                      labelText: "Choose Product Type",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (value) {
                      if (value != null)
                        productDetailsNotifier.setProductType(value);
                    },
                    validator: (value) {
                      if (value == null) return "Please select a product type";
                      return null;
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildUploadImagesTile(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  "Upload Images",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_a_photo),
                label: Text("Add Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  addImageButtonCallback(index: null);
                },
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(12)),
            Consumer(
              builder: (context, ref, child) {
                final productDetailsState = ref.watch(productDetailsProvider);
                final productDetailsNotifier = ref.read(
                  productDetailsProvider.notifier,
                );
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    productDetailsState.selectedImages.length,
                    (index) => Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            addImageButtonCallback(index: index);
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              color: Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child:
                                  productDetailsState
                                          .selectedImages[index]
                                          .imgType ==
                                      ImageType.local
                                  ? kIsWeb
                                        ? (productDetailsState
                                                      .selectedImages[index]
                                                      .xFile !=
                                                  null
                                              ? FutureBuilder<Uint8List>(
                                                  future: productDetailsState
                                                      .selectedImages[index]
                                                      .xFile!
                                                      .readAsBytes(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        fit: BoxFit.cover,
                                                      );
                                                    } else {
                                                      return Container(
                                                        color: Colors.grey[300],
                                                        child: Icon(
                                                          Icons.image,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: Icon(
                                                    Icons.image,
                                                    color: Colors.grey[600],
                                                  ),
                                                ))
                                        : Image.file(
                                            File(
                                              productDetailsState
                                                  .selectedImages[index]
                                                  .path,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                  : Base64ImageService().base64ToImage(
                                      productDetailsState
                                          .selectedImages[index]
                                          .path,
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              productDetailsNotifier.removeSelectedImageAtIndex(
                                index,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTitleField() {
    return TextFormField(
      controller: titleFieldController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: "e.g., Fresh Rohu Fish 1kg",
        labelText: "Product Title",
        prefixIcon: Icon(Icons.shopping_bag),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (titleFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildVariantField() {
    return TextFormField(
      controller: variantFieldController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: "e.g., Large Size, Boneless",
        labelText: "Variant",
        prefixIcon: Icon(Icons.category),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (variantFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildHighlightsField() {
    return TextFormField(
      controller: highlightsFieldController,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: "e.g., Wild caught | Cleaned & gutted | Rich in Omega-3",
        labelText: "Highlights",
        prefixIcon: Icon(Icons.star),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (highlightsFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      maxLines: null,
    );
  }

  Widget buildDescriptionField() {
    return TextFormField(
      controller: desciptionFieldController,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText:
            "e.g., Fresh Rohu fish sourced from local waters. Cleaned, gutted, and packed hygienically. Perfect for curries and fries.",
        labelText: "Description",
        prefixIcon: Icon(Icons.description),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (desciptionFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      maxLines: null,
    );
  }

  Widget buildSellerField() {
    return TextFormField(
      controller: sellerFieldController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: "e.g., FreshFish Mart",
        labelText: "Seller",
        prefixIcon: Icon(Icons.store),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (sellerFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildOriginalPriceField() {
    return TextFormField(
      controller: originalPriceFieldController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "e.g., 499.0",
        labelText: "Original Price (in INR)",
        prefixIcon: Icon(Icons.price_change),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (originalPriceFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildDiscountPriceField() {
    return TextFormField(
      controller: discountPriceFieldController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "e.g., 399.0",
        labelText: "Discount Price (in INR)",
        prefixIcon: Icon(Icons.discount),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (discountPriceFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildAreaLocationField(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: TextFormField(
          controller: areaLocationFieldController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: areaLocationFieldController.text.isNotEmpty
                ? areaLocationFieldController.text
                : "Enter area location",
            labelText: "Area Location",
            prefixIcon: Icon(Icons.location_on),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          validator: (_) {
            if (areaLocationFieldController.text.isEmpty) {
              return FIELD_REQUIRED_MSG;
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
  }

  Future<void> saveProductButtonCallback(BuildContext context) async {
    final productDetailsState = ref.read(productDetailsProvider);
    // Always assign productType and vendorId to product before validation
    product.productType = productDetailsState.productType;
    // Set vendorId if missing (required for Firestore path)
    if (product.vendorId == null || product.vendorId!.isEmpty) {
      try {
        // Try to get current user ID from AuthentificationService
        final _uid = AuthentificationService().currentUser.uid;
        if (_uid.isNotEmpty) {
          product.vendorId = _uid;
        }
      } catch (e) {
        Logger().w('Could not fetch current user ID: $e');
      }
    }
    // Ensure product.id is set for update
    if (!newProduct && product.id.isEmpty) {
      Logger().w('Product ID is missing for update!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Product ID is missing. Cannot update product.')),
        );
      }
      return;
    }
    if (validateBasicDetailsForm() == false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erros in Basic Details Form")));
      return;
    }
    if (validateDescribeProductForm() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errors in Describe Product Form")),
      );
      return;
    }
    if (productDetailsState.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload atleast One Image of Product")),
      );
      return;
    }
    if (productDetailsState.productType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select Product Category (Type)")),
      );
      return;
    }
    // Extra validation for all required fields
    final missingFields = <String>[];
    if (product.title == null || product.title!.isEmpty) missingFields.add('title');
    if (product.originalPrice == null) missingFields.add('originalPrice');
    if (product.discountPrice == null) missingFields.add('discountPrice');
    if (product.seller == null || product.seller!.isEmpty) missingFields.add('seller');
    if (product.stock == null) missingFields.add('stock');
    if (areaLocationFieldController.text.isEmpty) missingFields.add('areaLocation');
    if (product.productType == null) missingFields.add('productType');
    if (missingFields.isNotEmpty) {
      Logger().w('Missing required fields: ${missingFields.join(', ')}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing required fields: ${missingFields.join(', ')}')),
      );
      return;
    }
    // Log product data for debugging
    Logger().i('Saving product: ${product.toMap()}');
    String? productId;
    String snackbarMessage = "";
    try {
      final productUploadFuture = newProduct
          ? ProductDatabaseHelper().addUsersProduct(product)
          : ProductDatabaseHelper().updateUsersProduct(product);
      productId = await showDialog(
        context: context,
        builder: (context) {
          return AsyncProgressDialog(
            productUploadFuture,
            message: Text(newProduct ? "Uploading Images" : "Updating Images"),
          );
        },
      );
      if (productId != null) {
        snackbarMessage = "Product Info updated successfully";
      } else {
        throw "Couldn't update product info due to some unknown issue";
      }
    } catch (e) {
      Logger().w("Exception: $e");
      snackbarMessage = e.toString();
    } finally {
      Logger().i(snackbarMessage);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    if (productId == null) return;
    bool allImagesUploaded = false;
    try {
      allImagesUploaded = await uploadProductImages(productId);
      if (allImagesUploaded) {
        snackbarMessage = "All images uploaded successfully";
      } else {
        throw "Some images couldn't be uploaded, please try again";
      }
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
      snackbarMessage = "Something went wrong";
    } catch (e) {
      Logger().w("Unknown Exception: $e");
      snackbarMessage = "Something went wrong";
    } finally {
      Logger().i(snackbarMessage);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    // Always convert all selected images to base64 before uploading
    List<String> base64Images = [];
    for (final img in productDetailsState.selectedImages) {
      String? base64Image;
      try {
        if (img.imgType == ImageType.network) {
          // Already base64
          base64Image = img.path;
        } else if (img.imgType == ImageType.local) {
          if (img.xFile != null) {
            base64Image = await Base64ImageService().xFileToBase64(img.xFile!);
          } else {
            // Fallback to file path method for mobile/desktop
            base64Image = await Base64ImageService().fileToBase64(
              File(img.path),
            );
          }
        }
      } catch (e) {
        Logger().w("Error converting image to base64 for Firestore upload: $e");
      }
      // If conversion fails, use a placeholder image (never allow null)
      if (base64Image == null || base64Image.isEmpty) {
        base64Image = "PLACEHOLDER_IMAGE_URL_OR_BASE64";
      }
      base64Images.add(base64Image);
    }
    // Debug: print images and productId
    Logger().i('Uploading images for productId: $productId');
    Logger().i('base64Images: \\${base64Images.length}');
    for (var i = 0; i < base64Images.length; i++) {
      Logger().i('Image $i: \\${base64Images[i].substring(0, 30)}...');
    }
    bool productFinalizeUpdate = false;
    try {
      final updateProductFuture = ProductDatabaseHelper().updateProductsImages(
        productId,
        base64Images,
      );
      productFinalizeUpdate = await showDialog(
        context: context,
        builder: (context) {
          return AsyncProgressDialog(
            updateProductFuture,
            message: Text("Saving Product"),
          );
        },
      );
      if (productFinalizeUpdate) {
        snackbarMessage = "Product uploaded successfully";
      } else {
        throw "Couldn't upload product properly, please retry";
      }
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
      snackbarMessage = "Something went wrong";
    } catch (e) {
      Logger().w("Unknown Exception: $e");
      snackbarMessage = e.toString();
    } finally {
      Logger().i(snackbarMessage);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    if (mounted) {
      // Clear selected images after successful upload
      final productDetailsNotifier = ref.read(productDetailsProvider.notifier);
      productDetailsNotifier.clearSelectedImages();
      Navigator.pop(context);
    }
  }

  Future<bool> uploadProductImages(String productId) async {
    bool allImagesUpdated = true;
    final productDetailsState = ref.read(productDetailsProvider);
    final productDetailsNotifier = ref.read(productDetailsProvider.notifier);
    for (int i = 0; i < productDetailsState.selectedImages.length; i++) {
      if (productDetailsState.selectedImages[i].imgType == ImageType.local) {
        Logger().i(
          "Image being processed: ${productDetailsState.selectedImages[i].path}",
        );
        String? base64Image;
        try {
          // Always use XFile for base64 conversion if available (cross-platform)
          final xFile = productDetailsState.selectedImages[i].xFile;
          if (xFile != null) {
            base64Image = await Base64ImageService().xFileToBase64(xFile);
          } else {
            // Fallback to file path method (should rarely be needed)
            final file = File(productDetailsState.selectedImages[i].path);
            base64Image = await Base64ImageService().fileToBase64(file);
          }
        } catch (e) {
          Logger().w("Error converting image to base64: $e");
        } finally {
          if (base64Image != null) {
            Logger().i(
              "Base64 string length: " + base64Image.length.toString(),
            );
            productDetailsNotifier.setSelectedImageAtIndex(
              CustomImage(imgType: ImageType.network, path: base64Image),
              i,
            );
          } else {
            allImagesUpdated = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Couldn't process image ${i + 1} due to some issue",
                  ),
                ),
              );
            }
          }
        }
      }
    }
    return allImagesUpdated;
  }

  Future<void> addImageButtonCallback({int? index}) async {
    final productDetailsState = ref.read(productDetailsProvider);
    final productDetailsNotifier = ref.read(productDetailsProvider.notifier);
    if (index == null && productDetailsState.selectedImages.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Max 3 images can be uploaded")));
      }
      return;
    }
    ImagePickResult? result;
    String snackbarMessage = '';
    try {
      result = await choseImageFromLocalFiles(context);
    } on LocalFileHandlingException catch (e) {
      Logger().i("Local File Handling Exception: $e");
      snackbarMessage = e.toString();
    } catch (e) {
      Logger().i("Unknown Exception: $e");
      snackbarMessage = e.toString();
    } finally {
      if (snackbarMessage.isNotEmpty) {
        Logger().i(snackbarMessage);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        }
      }
    }
    if (result == null) {
      return;
    }
    if (index == null) {
      productDetailsNotifier.addNewSelectedImage(
        CustomImage(
          imgType: ImageType.local,
          path: result.path,
          xFile: result.xFile,
        ),
      );
    } else {
      productDetailsNotifier.setSelectedImageAtIndex(
        CustomImage(
          imgType: ImageType.local,
          path: result.path,
          xFile: result.xFile,
        ),
        index,
      );
    }
  }
}
