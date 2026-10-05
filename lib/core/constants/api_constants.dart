abstract final class ApiConstants {
  static const baseUrl = 'https://dummyjson.com';
  static const products = '/products';
  static const productSearch = '/products/search';

  static String product(int id) => '/products/$id';
}
