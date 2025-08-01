import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/models/Product.dart';
import 'package:fishkart_vendor/models/Review.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/services/cache/hive_service.dart';

// ...existing code...
class ProductDatabaseHelper {
  /// Get the current stock_remaining for a product
  Future<int?> getProductStockRemaining(String productId) async {
    final doc = await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .collection('stock')
        .doc('current')
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data != null ? data['stock_remaining'] as int? : null;
    }
    return null;
  }

  /// Update the stock_remaining for a product
  Future<void> updateProductStockRemaining(
    String productId,
    int newStock,
  ) async {
    await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .collection('stock')
        .doc('current')
        .update({'stock_remaining': newStock});
  }

  static const String PRODUCTS_COLLECTION_NAME = "products";
  static const String REVIEWS_COLLECTION_NAME = "reviews";

  ProductDatabaseHelper._privateConstructor();
  static final ProductDatabaseHelper _instance =
      ProductDatabaseHelper._privateConstructor();
  factory ProductDatabaseHelper() => _instance;

  late final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firebaseFirestore;

  /// Add stock subcollection for a product
  Future<void> addProductStockSubcollection(
    String productId,
    int stockRemaining,
  ) async {
    await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .collection('stock')
        .doc('current')
        .set({
          'stock_remaining': stockRemaining,
          'stock_reserved': 0,
          'stock_ordered': 0,
          'stock_completed': 0,
        });
  }

  /// Get product IDs by category with pagination and caching
  Future<List<String>> getProductIdsByCategory(
    ProductType productType, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool forceRefresh = false,
    void Function(String message)? onError,
  }) async {
    final productTypeStr = productType.toString().split('.').last;
    // Try cache first
    if (!forceRefresh) {
      final cached = HiveService.instance.getCachedProductsByType(productType);
      if (cached.isNotEmpty) {
        return cached.map((p) => p.id).toList();
      }
    }
    try {
      Query query = _firebaseFirestore
          .collection(PRODUCTS_COLLECTION_NAME)
          .where(Product.PRODUCT_TYPE_KEY, isEqualTo: productTypeStr)
          .where('vendorId', isEqualTo: AuthentificationService().currentUser.uid)
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final productsQuery = await query.get();
      // Optionally update cache
      if (productsQuery.docs.isNotEmpty) {
        // You may want to cache the products here
        // HiveService.instance.cacheProducts(productsQuery.docs.map((doc) => Product.fromMap(doc.data(), id: doc.id)).toList());
      }
      return productsQuery.docs.map((doc) => doc.id).toList();
    } on TypeError catch (e) {
      final errorMsg = 'A data type error occurred. Please check your Firestore fields. Details: ${e.toString()}';
      if (onError != null) onError(errorMsg);
      throw Exception(errorMsg);
    } catch (e) {
      final errorMsg = 'Error getting products by category: ${e.toString()}';
      print(errorMsg);
      if (onError != null) onError(errorMsg);
      throw Exception(errorMsg);
    }
  }

  Future<List<String>> searchInProducts(
    String query, {
    ProductType? productType,
  }) async {
    Query queryRef;
    if (productType == null) {
      queryRef = firestore.collection(PRODUCTS_COLLECTION_NAME);
    } else {
      // Use simple enum name that matches how we store it
      final productTypeStr = productType.toString().split('.').last;
      print("Searching with product type: $productTypeStr");

      queryRef = firestore
          .collection(PRODUCTS_COLLECTION_NAME)
          .where(Product.PRODUCT_TYPE_KEY, isEqualTo: productTypeStr);
    }

    final lowerQuery = query.toLowerCase();
    final Set<String> productsId = {};

    final querySearchInTags = await queryRef
        .where(Product.SEARCH_TAGS_KEY, arrayContains: query)
        .get();
    for (final doc in querySearchInTags.docs) {
      productsId.add(doc.id);
    }

    final queryDocs = await queryRef.get();
    for (final doc in queryDocs.docs) {
      final product = Product.fromMap(
        doc.data() as Map<String, dynamic>,
        id: doc.id,
      );
      if (product.title?.toLowerCase().contains(lowerQuery) == true ||
          product.description?.toLowerCase().contains(lowerQuery) == true ||
          product.highlights?.toLowerCase().contains(lowerQuery) == true ||
          product.variant?.toLowerCase().contains(lowerQuery) == true ||
          product.seller?.toLowerCase().contains(lowerQuery) == true) {
        productsId.add(product.id);
      }
    }

    return productsId.toList();
  }

  Future<bool> addProductReview(String productId, Review review) async {
    final reviewRef = firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .collection(REVIEWS_COLLECTION_NAME)
        .doc(review.reviewerUid);

    final reviewDoc = await reviewRef.get();

    if (!reviewDoc.exists) {
      await reviewRef.set(review.toMap());
      return addUsersRatingForProduct(productId, review.rating);
    } else {
      final oldRating = reviewDoc.data()?[Review.RATING_KEY] ?? 0;
      await reviewRef.update(review.toUpdateMap());
      return addUsersRatingForProduct(
        productId,
        review.rating,
        oldRating: oldRating,
      );
    }
  }

  Future<bool> addUsersRatingForProduct(
    String productId,
    int rating, {
    int? oldRating,
  }) async {
    final productRef = firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId);
    final reviews = await productRef.collection(REVIEWS_COLLECTION_NAME).get();
    final ratingsCount = reviews.docs.length;

    final productDoc = await productRef.get();
    final prevRating = (productDoc.data()?[Product.RATING_KEY] ?? 0).toDouble();

    double newRating;
    if (oldRating == null) {
      newRating = (prevRating * (ratingsCount - 1) + rating) / ratingsCount;
    } else {
      newRating =
          (prevRating * ratingsCount + rating - oldRating) / ratingsCount;
    }

    await productRef.update({
      Product.RATING_KEY: double.parse(newRating.toStringAsFixed(1)),
    });

    return true;
  }

  Future<Review?> getProductReviewWithID(
    String productId,
    String reviewId,
  ) async {
    final reviewDoc = await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .collection(REVIEWS_COLLECTION_NAME)
        .doc(reviewId)
        .get();

    if (reviewDoc.exists) {
      return Review.fromMap(reviewDoc.data()!, id: reviewDoc.id);
    }
    return null;
  }

  Stream<List<Review>> getAllReviewsStreamForProductId(String productId) {
    return firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .collection(REVIEWS_COLLECTION_NAME)
        .snapshots()
        .map(
          (query) => query.docs
              .map((doc) => Review.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<Product?> getProductWithID(String productId) async {
    final doc = await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .get();
    if (doc.exists) {
      return Product.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }

  Future<String> addUsersProduct(Product product) async {
    final uid = AuthentificationService().currentUser.uid;
    final vendorId = uid;
    final productData = product.toMap()
      ..['vendorId'] = vendorId
      ..['areaLocation'] = product.areaLocation;

    final docRef = await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .add(productData);
    await docRef.update({
      Product.SEARCH_TAGS_KEY: FieldValue.arrayUnion([
        productData[Product.PRODUCT_TYPE_KEY].toString().toLowerCase(),
      ]),
    });
    return docRef.id;
  }

  Future<bool> deleteUserProduct(String productId) async {
    await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId)
        .delete();
    // Remove from Hive cache as well
    await HiveService.instance.removeCachedProduct(productId);
    return true;
  }

  Future<String> updateUsersProduct(Product product) async {
    final productData = product.toUpdateMap();
    final docRef = firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(product.id);

    await docRef.update(productData);
    if (product.productType != null) {
      await docRef.update({
        Product.SEARCH_TAGS_KEY: FieldValue.arrayUnion([
          productData[Product.PRODUCT_TYPE_KEY].toString().toLowerCase(),
        ]),
      });
    }

    return docRef.id;
  }

  /// Get category products list with pagination and caching
  Future<List<String>> getCategoryProductsList(
    ProductType productType, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool forceRefresh = false,
  }) async {
    return getProductIdsByCategory(
      productType,
      limit: limit,
      startAfter: startAfter,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<String>> get usersProductsList async {
    final vendorId = AuthentificationService().currentUser.uid;
    final querySnapshot = await firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .where('vendorId', isEqualTo: vendorId)
        .get();

    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> get allProductsList async {
    final products = await firestore.collection(PRODUCTS_COLLECTION_NAME).get();
    return products.docs.map((doc) => doc.id).toList();
  }

  Future<bool> updateProductsImages(
    String productId,
    List<String> base64Images,
  ) async {
    final docRef = firestore
        .collection(PRODUCTS_COLLECTION_NAME)
        .doc(productId);
    await docRef.update({Product.IMAGES_KEY: base64Images});
    return true;
  }

  /// Get all products with pagination and caching
  Future<List<String>> getAllProducts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool forceRefresh = false,
  }) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = HiveService.instance.getCachedProducts();
      if (cached.isNotEmpty) {
        return cached.map((p) => p.id).toList();
      }
    }
    try {
      Query query = _firebaseFirestore
          .collection(PRODUCTS_COLLECTION_NAME)
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final querySnapshot = await query.get();
      // Optionally update cache
      if (querySnapshot.docs.isNotEmpty) {
        // HiveService.instance.cacheProducts(querySnapshot.docs.map((doc) => Product.fromMap(doc.data(), id: doc.id)).toList());
      }
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error getting all products: $e");
      throw e;
    }
  }

  Future<List<String>> getLatestProducts(int limit) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection(PRODUCTS_COLLECTION_NAME)
          .orderBy(Product.DATE_ADDED_KEY, descending: true)
          .limit(limit)
          .get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error getting latest products: $e");
      throw e;
    }
  }
}
