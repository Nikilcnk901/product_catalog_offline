import '../../models/product.dart';

enum ProductListStatus { initial, loading, success, failure }

enum ProductDetailsStatus { initial, loading, success, failure }

class ProductState {
  const ProductState({
    this.listStatus = ProductListStatus.initial,
    this.products = const [],
    this.listErrorMessage,
    this.query = '',
    this.detailsStatus = ProductDetailsStatus.initial,
    this.selectedProduct,
    this.detailsErrorMessage,
  });

  final ProductListStatus listStatus;
  final List<Product> products;
  final String? listErrorMessage;
  final String query;
  final ProductDetailsStatus detailsStatus;
  final Product? selectedProduct;
  final String? detailsErrorMessage;

  bool get isEmpty =>
      listStatus == ProductListStatus.success && products.isEmpty;

  ProductState copyWith({
    ProductListStatus? listStatus,
    List<Product>? products,
    String? listErrorMessage,
    bool clearListError = false,
    String? query,
    ProductDetailsStatus? detailsStatus,
    Product? selectedProduct,
    bool clearSelectedProduct = false,
    String? detailsErrorMessage,
    bool clearDetailsError = false,
  }) {
    return ProductState(
      listStatus: listStatus ?? this.listStatus,
      products: products ?? this.products,
      listErrorMessage: clearListError
          ? null
          : (listErrorMessage ?? this.listErrorMessage),
      query: query ?? this.query,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      selectedProduct: clearSelectedProduct
          ? null
          : (selectedProduct ?? this.selectedProduct),
      detailsErrorMessage: clearDetailsError
          ? null
          : (detailsErrorMessage ?? this.detailsErrorMessage),
    );
  }
}
