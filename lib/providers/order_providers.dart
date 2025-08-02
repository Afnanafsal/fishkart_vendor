import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';

final ordersStreamProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final uid = AuthentificationService().currentUser.uid;
  return FirebaseFirestore.instance
      .collectionGroup('ordered_products')
      .where('vendor_id', isEqualTo: uid)
      .snapshots();
});
