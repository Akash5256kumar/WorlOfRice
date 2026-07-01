import 'package:equatable/equatable.dart';

import '../../data/repositories/product_detail_repository.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();
  @override
  List<Object?> get props => [];
}

final class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.detail);
  final ProductDetailModel detail;
  @override
  List<Object?> get props => [detail];
}

final class ProductDetailError extends ProductDetailState {
  const ProductDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
