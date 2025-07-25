import 'package:fishkart_vendor/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart_vendor/providers/product_edit_providers.dart';
import 'components/body.dart';

class EditProductScreen extends ConsumerWidget {
  final Product productToEdit;

  const EditProductScreen({Key? key, required this.productToEdit}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the product edit state if needed
    ref.read(productEditInitializerProvider(productToEdit.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
      ),
      body: Body(productToEdit: productToEdit),
    );
  }
}
