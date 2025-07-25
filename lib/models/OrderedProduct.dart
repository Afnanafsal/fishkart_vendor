import 'Model.dart';

class OrderedProduct extends Model {
  static const String PRODUCT_UID_KEY = "product_uid";
  static const String ORDER_DATE_KEY = "order_date";
  static const String ADDRESS_ID_KEY = "address_id";
  static const String QUANTITY_KEY = "quantity";

  String? productUid;
  String? orderDate;
  String? addressId;
  int quantity;

  OrderedProduct(
    String id, {
    this.productUid,
    this.orderDate,
    this.addressId,
    this.quantity = 1,
  }) : super(id);

  factory OrderedProduct.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return OrderedProduct(
      id,
      productUid: map[PRODUCT_UID_KEY],
      orderDate: map[ORDER_DATE_KEY],
      addressId: map[ADDRESS_ID_KEY],
      quantity: map[QUANTITY_KEY] ?? 1,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      PRODUCT_UID_KEY: productUid,
      ORDER_DATE_KEY: orderDate,
      ADDRESS_ID_KEY: addressId,
      QUANTITY_KEY: quantity,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (productUid != null) map[PRODUCT_UID_KEY] = productUid;
    if (orderDate != null) map[ORDER_DATE_KEY] = orderDate;
    if (addressId != null) map[ADDRESS_ID_KEY] = addressId;
    return map;
  }

  OrderedProduct copyWith({
    String? id,
    String? productUid,
    String? orderDate,
    String? addressId,
    int? quantity,
  }) {
    return OrderedProduct(
      (id ?? this.id),
      productUid: productUid ?? this.productUid,
      orderDate: orderDate ?? this.orderDate,
      addressId: addressId ?? this.addressId,
      quantity: quantity ?? this.quantity,
    );
  }
}
