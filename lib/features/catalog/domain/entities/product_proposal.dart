class ProductProposal {
  const ProductProposal({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.attributes,
    required this.status,
    this.rejectionReason,
  });

  final String id;
  final String categoryId;
  final String name;
  final String unit;
  final Map<String, dynamic> attributes;
  final String status;
  final String? rejectionReason;

  factory ProductProposal.fromJson(Map<String, dynamic> json) =>
      ProductProposal(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? const {}),
        status: json['status'] as String? ?? 'pending_review',
        rejectionReason: json['rejectionReason'] as String?,
      );
}

class CreateProductProposalRequest {
  const CreateProductProposalRequest({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
    this.attributes = const {},
    this.confirm,
  });

  final String id;
  final String categoryId;
  final String name;
  final String unit;
  final Map<String, dynamic> attributes;
  final bool? confirm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'unit': unit,
        'attributes': attributes,
        if (confirm != null) 'confirm': confirm,
      };
}
