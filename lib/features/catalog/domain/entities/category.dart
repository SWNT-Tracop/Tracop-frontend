class Category {
  final String id;
  final String name;
  final String? parentId;
  final int depth;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.depth,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        parentId: json['parentId'] as String?,
        depth: json['depth'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'depth': depth,
      };
}
