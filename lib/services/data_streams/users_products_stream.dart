import 'package:fishkart_vendor/services/data_streams/data_stream.dart';
import 'package:fishkart_vendor/services/database/product_database_helper.dart';

class UsersProductsStream extends DataStream<List<String>> {
  @override
  void reload() {
    final usersProductsFuture = ProductDatabaseHelper().usersProductsList;
    usersProductsFuture
        .then((data) {
          addData(data);
        })
        .catchError((e) {
          addError(e);
        });
  }
}
