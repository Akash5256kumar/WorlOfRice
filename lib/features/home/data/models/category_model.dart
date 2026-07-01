/// Maps one item from `GET /api/v1/categories`.
///
/// Confirmed field names from live response (no-header call, 2026-05-25):
/// { id, name, image_full_url, parent_id, module_id, status,
///   products_count, featured, childes, ... }
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageFullUrl,
    required this.productsCount,
    required this.featured,
    required this.parentId,
    required this.moduleId,
  });

  final int id;
  final String name;
  final String? imageFullUrl;
  final int productsCount;
  final bool featured;
  final int parentId;
  final int moduleId;

  bool get isRoot => parentId == 0;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      imageFullUrl: json['image_full_url'] as String?,
      productsCount: json['products_count'] as int? ?? 0,
      featured: (json['featured'] as int? ?? 0) == 1,
      parentId: json['parent_id'] as int? ?? 0,
      moduleId: json['module_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_full_url': imageFullUrl,
        'products_count': productsCount,
        'featured': featured ? 1 : 0,
        'parent_id': parentId,
        'module_id': moduleId,
      };
}
