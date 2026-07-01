import 'package:equatable/equatable.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object?> get props => [];
}

final class ProductDetailStarted extends ProductDetailEvent {
  const ProductDetailStarted(this.slug);
  final String slug;
  @override
  List<Object?> get props => [slug];
}
