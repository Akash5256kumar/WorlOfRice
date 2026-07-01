import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/product_detail_repository.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc({ProductDetailRepository? repository})
      : _repo = repository ?? ProductDetailRepository(),
        super(const ProductDetailInitial()) {
    on<ProductDetailStarted>(_onStarted);
  }

  final ProductDetailRepository _repo;

  Future<void> _onStarted(
      ProductDetailStarted event, Emitter<ProductDetailState> emit) async {
    emit(const ProductDetailLoading());
    try {
      final detail = await _repo.getDetail(event.slug);
      // Emit immediately so the page is usable while related items load.
      emit(ProductDetailLoaded(detail));
      debugPrint('[ProductDetailBloc] loaded: ${detail.product.name}');

      try {
        final related = await _repo.getRelatedItems(detail.product.id);
        emit(ProductDetailLoaded(detail.copyWith(relatedItems: related)));
        debugPrint('[ProductDetailBloc] related items: ${related.length}');
      } catch (e) {
        debugPrint('[ProductDetailBloc] related items error (non-fatal): $e');
      }
    } catch (e) {
      debugPrint('[ProductDetailBloc] error: $e');
      emit(ProductDetailError(e.toString()));
    }
  }
}
