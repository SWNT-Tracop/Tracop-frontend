class Product {
  final String id;
  final String categoryId;
  final String name;
  final String unit;
  final Map<String, dynamic> attributes;

  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.attributes,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        attributes: Map<String, dynamic>.from(json['attributes'] as Map),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'unit': unit,
        'attributes': attributes,
      };
}
