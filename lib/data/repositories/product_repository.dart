import '../../models/product.dart';
import '../remote/product_api.dart';

class ProductRepository {
  ProductRepository({ProductApi? api}) : _api = api ?? ProductApi();

  final ProductApi _api;

  Future<List<Product>> getProducts() => _api.getProducts();

  Future<List<Product>> searchProducts(String query) =>
      _api.searchProducts(query);

  Future<Product> getProduct(int id) => _api.getProduct(id);
}
