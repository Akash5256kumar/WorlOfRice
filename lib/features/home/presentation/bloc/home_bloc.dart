import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({HomeRepository? repository})
      : _repo = repository ?? HomeRepository(),
        super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeCategorySelected>(_onCategorySelected);
    on<HomeNextPageRequested>(_onNextPage);
    on<HomeSearchChanged>(_onSearchChanged);
  }

  final HomeRepository _repo;

  static const _pageSize = 12;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] HomeStarted');
    emit(const HomeLoading());
    try {
      debugPrint('[HomeBloc] fetching categories…');
      final categories = await _repo.getCategories();
      debugPrint('[HomeBloc] got ${categories.length} categories');

      debugPrint('[HomeBloc] fetching products and trending in parallel…');
      // Fire both requests concurrently; trending failure is non-fatal (returns []).
      final resultFuture = _repo.getProducts(limit: _pageSize);
      final trendingFuture = _repo.getTrendingProducts();

      final result = await resultFuture;
      final trendingProducts = await trendingFuture;

      final products = result.products;
      final totalSize = result.totalSize;
      debugPrint('[HomeBloc] got ${products.length} products (total=$totalSize), ${trendingProducts.length} trending');

      debugPrint('[HomeBloc] emitting HomeLoaded');
      emit(HomeLoaded(
        categories: categories,
        products: products,
        trendingProducts: trendingProducts,
        selectedCategoryId: null, // "All" selected initially
        totalSize: totalSize,
        currentPage: 1,
      ));
    } catch (e, st) {
      debugPrint('[HomeBloc] FATAL $e\n$st');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onCategorySelected(
      HomeCategorySelected event, Emitter<HomeState> emit) async {
    final current = state;
    if (current is! HomeLoaded) return;

    // Immediately show loading state for the products section
    emit(current.copyWith(
      clearCategory: event.categoryId == null,
      selectedCategoryId: event.categoryId,
      products: [],
      totalSize: 0,
      currentPage: 1,
      isLoadingMore: true,
    ));

    try {
      // null = "All" → empty category_ids = all products
      // non-null = specific category → filter by that ID
      final categoryIds = event.categoryId != null ? [event.categoryId!] : <int>[];
      debugPrint('[HomeBloc] category selected: ${event.categoryId ?? "All"} → ids=$categoryIds, query="${current.searchQuery}"');

      final result = await _repo.getProducts(
        categoryIds: categoryIds,
        name: current.searchQuery,
        limit: _pageSize,
      );
      debugPrint('[HomeBloc] category products: ${result.products.length} (total=${result.totalSize})');

      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(
          products: result.products,
          totalSize: result.totalSize,
          currentPage: 1,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      debugPrint('[HomeBloc] category load failed → $e');
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(
          products: [],
          totalSize: 0,
          currentPage: 1,
          isLoadingMore: false,
        ));
      }
    }
  }

  Future<void> _onSearchChanged(
      HomeSearchChanged event, Emitter<HomeState> emit) async {
    final current = state;
    if (current is! HomeLoaded) return;

    // Save the query immediately so pagination and category handlers can see it.
    emit(current.copyWith(
      products: [],
      totalSize: 0,
      currentPage: 1,
      isLoadingMore: true,
      searchQuery: event.query,
    ));
    try {
      final categoryIds = current.selectedCategoryId != null
          ? [current.selectedCategoryId!]
          : <int>[];
      debugPrint('[HomeBloc] search: query="${event.query}" categoryIds=$categoryIds');
      final result = await _repo.getProducts(
        categoryIds: categoryIds,
        name: event.query,
        limit: _pageSize,
      );
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(
          products: result.products,
          totalSize: result.totalSize,
          currentPage: 1,
          isLoadingMore: false,
        ));
      }
    } catch (_) {
      if (state is HomeLoaded) emit((state as HomeLoaded).copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onNextPage(
      HomeNextPageRequested event, Emitter<HomeState> emit) async {
    final current = state;
    if (current is! HomeLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      // Preserve the current category filter for pagination
      final categoryIds = current.selectedCategoryId != null
          ? [current.selectedCategoryId!]
          : <int>[];

      final result = await _repo.getProducts(
        categoryIds: categoryIds,
        name: current.searchQuery,
        offset: nextPage,
        limit: _pageSize,
      );

      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(
          products: [...current.products, ...result.products],
          totalSize: result.totalSize,
          currentPage: nextPage,
          isLoadingMore: false,
        ));
      }
    } catch (_) {
      if (state is HomeLoaded) emit((state as HomeLoaded).copyWith(isLoadingMore: false));
    }
  }
}
