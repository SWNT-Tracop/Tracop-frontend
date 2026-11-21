class OrderCandidate {
  const OrderCandidate({
    required this.orderId,
    required this.deliveryZone,
    required this.deliveryWindow,
    required this.pickupZones,
    required this.lines,
    this.isLocalPayment = false,
  });

  final String orderId;
  final String deliveryZone;
  final DateTime? deliveryWindow;
  final List<String> pickupZones;
  final List<CandidateLine> lines;
  final bool isLocalPayment;

  factory OrderCandidate.fromJson(Map<String, dynamic> json) => OrderCandidate(
        orderId: json['orderId'] as String,
        deliveryZone: json['deliveryZone'] as String,
        deliveryWindow: json['deliveryWindow'] == null
            ? null
            : DateTime.parse(json['deliveryWindow'] as String),
        pickupZones: (json['pickupZones'] as List).cast<String>(),
        lines: (json['lines'] as List)
            .map((line) =>
                CandidateLine.fromJson(Map<String, dynamic>.from(line as Map)))
            .toList(growable: false),
        isLocalPayment: json['isLocalPayment'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'deliveryZone': deliveryZone,
        'deliveryWindow': deliveryWindow?.toIso8601String(),
        'pickupZones': pickupZones,
        'lines': lines.map((line) => line.toJson()).toList(),
        'isLocalPayment': isLocalPayment,
      };
}

class CandidateLine {
  const CandidateLine({
    required this.lotId,
    required this.quantityMilli,
    required this.unit,
  });

  final String lotId;
  final String quantityMilli;
  final String unit;

  factory CandidateLine.fromJson(Map<String, dynamic> json) => CandidateLine(
        lotId: json['lotId'] as String,
        quantityMilli: json['quantityMilli'] as String,
        unit: json['unit'] as String,
      );

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'quantityMilli': quantityMilli,
        'unit': unit,
      };
}

class CarrierTrip {
  const CarrierTrip({
    required this.id,
    required this.status,
    required this.version,
    required this.plannedAt,
    this.isLocalOnly = false,
  });

  final String id;
  final String status;
  final int version;
  final DateTime plannedAt;
  final bool isLocalOnly;

  factory CarrierTrip.fromJson(Map<String, dynamic> json) => CarrierTrip(
        id: json['id'] as String,
        status: json['status'] as String,
        version: json['version'] as int,
        plannedAt: DateTime.parse(json['plannedAt'] as String),
        isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'version': version,
        'plannedAt': plannedAt.toIso8601String(),
        'isLocalOnly': isLocalOnly,
      };

  CarrierTrip copyWith({String? status, int? version}) => CarrierTrip(
        id: id,
        status: status ?? this.status,
        version: version ?? this.version,
        plannedAt: plannedAt,
        isLocalOnly: isLocalOnly,
      );
}

class TripStop {
  const TripStop({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.sequence,
    required this.zone,
    required this.completedAt,
  });

  final String id;
  final String orderId;
  final String kind;
  final int sequence;
  final String zone;
  final DateTime? completedAt;

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        kind: json['kind'] as String,
        sequence: json['sequence'] as int,
        zone: json['zone'] as String,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'kind': kind,
        'sequence': sequence,
        'zone': zone,
        'completedAt': completedAt?.toIso8601String(),
      };
}

class CarrierProfile {
  const CarrierProfile({
    required this.vehicleType,
    required this.capacityKg,
    required this.plate,
  });

  final String vehicleType;
  final int capacityKg;
  final String plate;

  factory CarrierProfile.fromJson(Map<String, dynamic> json) => CarrierProfile(
        vehicleType: json['vehicleType'] as String,
        capacityKg: json['capacityKg'] as int,
        plate: json['plate'] as String,
      );

  Map<String, dynamic> toJson() => {
        'vehicleType': vehicleType,
        'capacityKg': capacityKg,
        'plate': plate,
      };
}
