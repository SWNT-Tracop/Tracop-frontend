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

class ProviderSummary {
  final String displayName;
  final String municipality;
  final String department;

  const ProviderSummary({
    required this.displayName,
    required this.municipality,
    required this.department,
  });

  factory ProviderSummary.fromJson(Map<String, dynamic> json) =>
      ProviderSummary(
        displayName: json['displayName'] as String,
        municipality: json['municipality'] as String,
        department: json['department'] as String,
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'municipality': municipality,
        'department': department,
      };
}

class Lot {
  final String id;
  final String? providerId;
  final String productId;
  final String quantityMilli;
  final String unit;
  final String unitPrice;
  final String? qualityGrade;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final String status;
  final int version;
  final ProviderSummary? provider;
  final double? distanceKm;
  final bool isMine;

  const Lot({
    required this.id,
    this.providerId,
    required this.productId,
    required this.quantityMilli,
    required this.unit,
    required this.unitPrice,
    this.qualityGrade,
    required this.availableFrom,
    required this.availableUntil,
    required this.status,
    required this.version,
    this.provider,
    this.distanceKm,
    this.isMine = false,
  });

  factory Lot.fromJson(Map<String, dynamic> json) => Lot(
        id: json['id'] as String,
        providerId: json['providerId'] as String?,
        productId: json['productId'] as String,
        quantityMilli: json['quantityMilli'] as String,
        unit: json['unit'] as String,
        unitPrice: json['unitPrice'] as String,
        qualityGrade: json['qualityGrade'] as String?,
        availableFrom: DateTime.parse(json['availableFrom'] as String),
        availableUntil: DateTime.parse(json['availableUntil'] as String),
        status: json['status'] as String,
        version: json['version'] as int,
        provider: json['provider'] != null
            ? ProviderSummary.fromJson(json['provider'] as Map<String, dynamic>)
            : null,
        distanceKm: json['distanceKm'] is num
            ? (json['distanceKm'] as num).toDouble()
            : null,
        isMine: json['isMine'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerId': providerId,
        'productId': productId,
        'quantityMilli': quantityMilli,
        'unit': unit,
        'unitPrice': unitPrice,
        'qualityGrade': qualityGrade,
        'availableFrom': availableFrom.toIso8601String(),
        'availableUntil': availableUntil.toIso8601String(),
        'status': status,
        'version': version,
        'provider': provider?.toJson(),
        'distanceKm': distanceKm,
        'isMine': isMine,
      };

  Map<String, dynamic> toJsonWithoutProvider() => {
        'id': id,
        'productId': productId,
        'quantityMilli': quantityMilli,
        'unit': unit,
        'unitPrice': unitPrice,
        'qualityGrade': qualityGrade,
        'availableFrom': availableFrom.toIso8601String(),
        'availableUntil': availableUntil.toIso8601String(),
        'status': status,
        'version': version,
      };
}

class LotPage {
  final List<Lot> items;
  final String? nextCursor;

  const LotPage({required this.items, this.nextCursor});

  factory LotPage.fromJson(Map<String, dynamic> json) => LotPage(
        items: (json['items'] as List)
            .map((e) => Lot.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}

class CreateLotRequest {
  final String id;
  final String productId;
  final String quantityMilli;
  final String unit;
  final int unitPrice;
  final String? qualityGrade;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final double locationLat;
  final double locationLng;

  const CreateLotRequest({
    required this.id,
    required this.productId,
    required this.quantityMilli,
    required this.unit,
    required this.unitPrice,
    this.qualityGrade,
    required this.availableFrom,
    required this.availableUntil,
    required this.locationLat,
    required this.locationLng,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'quantityMilli': quantityMilli,
        'unit': unit,
        'unitPrice': unitPrice,
        'qualityGrade': qualityGrade,
        'availableFrom': availableFrom.toIso8601String(),
        'availableUntil': availableUntil.toIso8601String(),
        'locationLat': locationLat,
        'locationLng': locationLng,
      };
}

class UpdateLotRequest {
  final int version;
  final String? quantityMilli;
  final String? unit;
  final int? unitPrice;
  final String? qualityGrade;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final double? locationLat;
  final double? locationLng;

  const UpdateLotRequest({
    required this.version,
    this.quantityMilli,
    this.unit,
    this.unitPrice,
    this.qualityGrade,
    this.availableFrom,
    this.availableUntil,
    this.locationLat,
    this.locationLng,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        if (quantityMilli != null) 'quantityMilli': quantityMilli,
        if (unit != null) 'unit': unit,
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (qualityGrade != null) 'qualityGrade': qualityGrade,
        if (availableFrom != null)
          'availableFrom': availableFrom!.toIso8601String(),
        if (availableUntil != null)
          'availableUntil': availableUntil!.toIso8601String(),
        if (locationLat != null) 'locationLat': locationLat,
        if (locationLng != null) 'locationLng': locationLng,
      };
}

class PublishCancelRequest {
  final int version;

  const PublishCancelRequest({required this.version});

  Map<String, dynamic> toJson() => {'version': version};
}
