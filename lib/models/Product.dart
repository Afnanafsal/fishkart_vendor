import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:fishkart_vendor/models/Model.dart';

enum ProductType { Freshwater, Saltwater, Shellfish, Exotic, Others, Dried }

class Product extends Model {
  static const String VENDOR_ID_KEY = "vendorId";
  static const String VENDOR_LOCATION_KEY = "vendor_location";

  /// Stock management methods for Firestore
  static Future<void> reserveStock(String productId, int qty) async {
    final stockRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('stock')
        .doc('current');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(stockRef);
      final data = snapshot.data()!;
      transaction.update(stockRef, {
        'stock_remaining': (data['stock_remaining'] ?? 0) - qty,
        'stock_reserved': (data['stock_reserved'] ?? 0) + qty,
      });
    });
  }

  static Future<void> unreserveStock(String productId, int qty) async {
    final stockRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('stock')
        .doc('current');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(stockRef);
      final data = snapshot.data()!;
      transaction.update(stockRef, {
        'stock_remaining': (data['stock_remaining'] ?? 0) + qty,
        'stock_reserved': (data['stock_reserved'] ?? 0) - qty,
      });
    });
  }

  static Future<void> orderStock(String productId, int qty) async {
    final stockRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('stock')
        .doc('current');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(stockRef);
      final data = snapshot.data()!;
      transaction.update(stockRef, {
        'stock_reserved': (data['stock_reserved'] ?? 0) - qty,
        'stock_ordered': (data['stock_ordered'] ?? 0) + qty,
      });
    });
  }

  static Future<void> completeOrderStock(String productId, int qty) async {
    final stockRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('stock')
        .doc('current');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(stockRef);
      final data = snapshot.data()!;
      transaction.update(stockRef, {
        'stock_ordered': (data['stock_ordered'] ?? 0) - qty,
        'stock_completed': (data['stock_completed'] ?? 0) + qty,
      });
    });
  }

  static const String IMAGES_KEY = "images";
  static const String TITLE_KEY = "title";
  static const String VARIANT_KEY = "variant";
  static const String DISCOUNT_PRICE_KEY = "discount_price";
  static const String ORIGINAL_PRICE_KEY = "original_price";
  static const String RATING_KEY = "rating";
  static const String HIGHLIGHTS_KEY = "highlights";
  static const String DESCRIPTION_KEY = "description";
  static const String SELLER_KEY = "seller";
  static const String PRODUCT_TYPE_KEY = "product_type";
  static const String SEARCH_TAGS_KEY = "search_tags";
  static const String DATE_ADDED_KEY = "dateAdded";

  List<String>? images;
  String? title;
  String? variant;
  num? discountPrice;
  num? originalPrice;
  num rating;
  String? highlights;
  String? description;
  String? seller;
  ProductType? productType;
  List<String>? searchTags;
  DateTime? dateAdded;
  int? stock;
  String? areaLocation;
  String? vendorId;
  bool? isAvailable;

  Product(
    String id, {
    this.images,
    this.title,
    this.variant,
    this.discountPrice,
    this.originalPrice,
    this.rating = 0.0,
    this.highlights,
    this.description,
    this.seller,
    this.productType,
    this.searchTags,
    this.dateAdded,
    this.stock,
    this.areaLocation,
    this.vendorId,
    this.isAvailable,
  }) : super(id);

  int calculatePercentageDiscount() {
    if (originalPrice == null || discountPrice == null || originalPrice == 0) {
      return 0;
    }
    return (((originalPrice! - discountPrice!) * 100) / originalPrice!).round();
  }

  factory Product.fromMap(Map<String, dynamic> map, {required String id}) {
    return Product(
      id,
      images: (map[IMAGES_KEY] as List<dynamic>?)?.cast<String>() ?? [],
      title: map[TITLE_KEY],
      variant: map[VARIANT_KEY],
      discountPrice: map[DISCOUNT_PRICE_KEY],
      originalPrice: map[ORIGINAL_PRICE_KEY],
      rating: map[RATING_KEY] ?? 0.0,
      highlights: map[HIGHLIGHTS_KEY],
      description: map[DESCRIPTION_KEY],
      seller: map[SELLER_KEY],
      productType: EnumToString.fromString(
        ProductType.values,
        map[PRODUCT_TYPE_KEY],
      ),
      searchTags:
          (map[SEARCH_TAGS_KEY] as List<dynamic>?)?.cast<String>() ?? [],
      dateAdded: map[DATE_ADDED_KEY] != null
          ? DateTime.tryParse(map[DATE_ADDED_KEY])
          : null,
      stock: map['stock'] is int
          ? map['stock']
          : int.tryParse(map['stock']?.toString() ?? ''),
      areaLocation: map['areaLocation'],
      vendorId: map[VENDOR_ID_KEY],
      isAvailable: map['isAvailable'] is bool ? map['isAvailable'] : (map['isAvailable'] == null ? null : map['isAvailable'].toString() == 'true'),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      IMAGES_KEY: images,
      TITLE_KEY: title,
      VARIANT_KEY: variant,
      DISCOUNT_PRICE_KEY: discountPrice,
      ORIGINAL_PRICE_KEY: originalPrice,
      RATING_KEY: rating,
      HIGHLIGHTS_KEY: highlights,
      DESCRIPTION_KEY: description,
      SELLER_KEY: seller,
      PRODUCT_TYPE_KEY: productType != null
          ? EnumToString.convertToString(productType)
          : null,
      SEARCH_TAGS_KEY: searchTags,
      DATE_ADDED_KEY: dateAdded?.toIso8601String(),
      'stock': stock,
      'areaLocation': areaLocation,
      VENDOR_ID_KEY: vendorId,
      'isAvailable': isAvailable,
    };
    return map;
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};

    if (images != null) map[IMAGES_KEY] = images;
    if (title != null) map[TITLE_KEY] = title;
    if (variant != null) map[VARIANT_KEY] = variant;
    if (discountPrice != null) map[DISCOUNT_PRICE_KEY] = discountPrice;
    if (originalPrice != null) map[ORIGINAL_PRICE_KEY] = originalPrice;
    map[RATING_KEY] = rating; // Always include rating
    if (highlights != null) map[HIGHLIGHTS_KEY] = highlights;
    if (description != null) map[DESCRIPTION_KEY] = description;
    if (seller != null) map[SELLER_KEY] = seller;
    if (productType != null) {
      map[PRODUCT_TYPE_KEY] = EnumToString.convertToString(productType);
    }
    if (searchTags != null) map[SEARCH_TAGS_KEY] = searchTags;
    if (dateAdded != null) map[DATE_ADDED_KEY] = dateAdded?.toIso8601String();
    if (stock != null) map['stock'] = stock;
    if (areaLocation != null) map['areaLocation'] = areaLocation;
    if (vendorId != null) map[VENDOR_ID_KEY] = vendorId;
    if (isAvailable != null) map['isAvailable'] = isAvailable;

    return map;
  }

  Product copyWith({
    String? id,
    List<String>? images,
    String? title,
    String? variant,
    num? discountPrice,
    num? originalPrice,
    num? rating,
    String? highlights,
    String? description,
    String? seller,
    ProductType? productType,
    List<String>? searchTags,
    DateTime? dateAdded,
    int? stock,
    String? areaLocation,
    String? vendorId,
    bool? isAvailable,
  }) {
    return Product(
      id ?? this.id,
      images: images ?? this.images,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      discountPrice: discountPrice ?? this.discountPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      highlights: highlights ?? this.highlights,
      description: description ?? this.description,
      seller: seller ?? this.seller,
      productType: productType ?? this.productType,
      searchTags: searchTags ?? this.searchTags,
      dateAdded: dateAdded ?? this.dateAdded,
      stock: stock ?? this.stock,
      areaLocation: areaLocation ?? this.areaLocation,
      vendorId: vendorId ?? this.vendorId,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
