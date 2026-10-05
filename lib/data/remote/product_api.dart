import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../models/product.dart';

const _unexpectedResponse =
    'The product service returned an unexpected response.';

class ProductApiException implements Exception {
  const ProductApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductApi {
  ProductApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  Future<List<Product>> getProducts() {
    return _fetchProducts(ApiConstants.products);
  }

  Future<List<Product>> searchProducts(String query) {
    return _fetchProducts(
      ApiConstants.productSearch,
      queryParameters: {'q': query},
    );
  }

  Future<Product> getProduct(int id) async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.product(id));
      return _parseProduct(response.data);
    } on DioException catch (error) {
      throw ProductApiException(_messageFor(error));
    } on FormatException {
      throw const ProductApiException(_unexpectedResponse);
    }
  }

  Future<List<Product>> _fetchProducts(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _parseProducts(response.data);
    } on DioException catch (error) {
      throw ProductApiException(_messageFor(error));
    } on FormatException {
      throw const ProductApiException(_unexpectedResponse);
    }
  }

  List<Product> _parseProducts(Object? data) {
    if (data is! Map) {
      throw const FormatException(_unexpectedResponse);
    }

    final products = data['products'];
    if (products is! List) {
      throw const FormatException(_unexpectedResponse);
    }

    final parsed = <Product>[];
    for (final product in products) {
      if (product is! Map) {
        throw const FormatException(_unexpectedResponse);
      }
      parsed.add(Product.fromJson(Map<String, dynamic>.from(product)));
    }
    return parsed;
  }

  Product _parseProduct(Object? data) {
    if (data is! Map) {
      throw const FormatException(_unexpectedResponse);
    }
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Check your connection and try again.';
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404) {
          return 'That product could not be found.';
        }
        return _unexpectedResponse;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return 'Something went wrong while loading products.';
    }
  }
}
