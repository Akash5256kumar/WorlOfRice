import 'package:equatable/equatable.dart';

import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.categories,
    required this.products,
    required this.selectedCategoryId,
    required this.totalSize,
    required this.currentPage,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.trendingProducts = const [],
  });

  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<ProductModel> trendingProducts;

  /// null = "All" selected.
  final int? selectedCategoryId;
  final int totalSize;
  final int currentPage;
  final bool isLoadingMore;

  /// The active search term; empty string means no filter.
  final String searchQuery;

  bool get hasMore => products.length < totalSize;

  HomeLoaded copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<ProductModel>? trendingProducts,
    int? selectedCategoryId,
    bool clearCategory = false,
    int? totalSize,
    int? currentPage,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return HomeLoaded(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      trendingProducts: trendingProducts ?? this.trendingProducts,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      totalSize: totalSize ?? this.totalSize,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        products,
        trendingProducts,
        selectedCategoryId,
        totalSize,
        currentPage,
        isLoadingMore,
        searchQuery,
      ];
}

final class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
