import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/remote/product_api.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/product.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repository) : super(const ProductState());

  final ProductRepository _repository;

  Future<void> loadProducts() {
    return _loadList(query: '', fetch: _repository.getProducts);
  }

  Future<void> searchProducts(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return loadProducts();
    }
    return _loadList(
      query: trimmed,
      fetch: () => _repository.searchProducts(trimmed),
    );
  }

  Future<void> loadProduct(int id) async {
    emit(
      state.copyWith(
        detailsStatus: ProductDetailsStatus.loading,
        clearSelectedProduct: true,
        clearDetailsError: true,
      ),
    );

    try {
      final product = await _repository.getProduct(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          detailsStatus: ProductDetailsStatus.success,
          selectedProduct: product,
        ),
      );
    } on ProductApiException catch (error) {
      _emitDetailsFailure(error.message);
    } catch (_) {
      _emitDetailsFailure('Something went wrong while loading this product.');
    }
  }

  Future<void> _loadList({
    required String query,
    required Future<List<Product>> Function() fetch,
  }) async {
    emit(
      state.copyWith(
        listStatus: ProductListStatus.loading,
        query: query,
        clearListError: true,
      ),
    );

    try {
      final products = await fetch();
      if (isClosed) return;
      emit(
        state.copyWith(
          listStatus: ProductListStatus.success,
          products: products,
        ),
      );
    } on ProductApiException catch (error) {
      _emitListFailure(error.message);
    } catch (_) {
      _emitListFailure('Something went wrong while loading products.');
    }
  }

  void _emitListFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        listStatus: ProductListStatus.failure,
        products: const [],
        listErrorMessage: message,
      ),
    );
  }

  void _emitDetailsFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        detailsStatus: ProductDetailsStatus.failure,
        clearSelectedProduct: true,
        detailsErrorMessage: message,
      ),
    );
  }
}
