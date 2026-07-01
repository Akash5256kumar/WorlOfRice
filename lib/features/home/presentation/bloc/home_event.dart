import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial load of categories and the first product page.
final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// User tapped a category pill — filters the product grid.
/// [categoryId] == null means "All".
final class HomeCategorySelected extends HomeEvent {
  const HomeCategorySelected(this.categoryId);

  final int? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

/// User reached the bottom of the product list — loads the next page.
final class HomeNextPageRequested extends HomeEvent {
  const HomeNextPageRequested();
}

/// User typed in the search box — reloads products matching [query].
final class HomeSearchChanged extends HomeEvent {
  const HomeSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
