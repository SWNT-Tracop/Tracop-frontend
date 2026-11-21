class OrderLine {
  const OrderLine({
    required this.lotId,
    required this.quantityMilli,
    required this.unit,
    required this.unitPrice,
  });

  final String lotId;
  final String quantityMilli;
  final String unit;
  final String unitPrice;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        lotId: json['lotId'] as String,
        quantityMilli: json['quantityMilli'] as String,
        unit: json['unit'] as String,
        unitPrice: json['unitPrice'] as String,
      );

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'quantityMilli': quantityMilli,
        'unit': unit,
        'unitPrice': unitPrice,
      };
}

class OrderLineInput {
  const OrderLineInput({required this.lotId, required this.quantityMilli});

  final String lotId;
  final String quantityMilli;

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'quantityMilli': quantityMilli,
      };
}

class QuoteAmounts {
  const QuoteAmounts({
    required this.subtotal,
    required this.freight,
    required this.commission,
    required this.total,
    required this.providerNet,
  });

  final String subtotal;
  final String freight;
  final String commission;
  final String total;
  final String providerNet;
}

class OrderResponse {
  const OrderResponse({
    required this.id,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.lines,
    required this.amounts,
    required this.acceptedAt,
    required this.cancelReason,
    required this.quoteValidUntil,
    this.isLocallyPaid = false,
    this.provider,
    this.deliveryAddress,
    this.deliveryWindow,
  });

  final String id;
  final String status;
  final int version;
  final DateTime createdAt;
  final List<OrderLine> lines;
  final QuoteAmounts amounts;
  final Map<String, dynamic>? provider;
  final String? deliveryAddress;
  final DateTime? deliveryWindow;
  final DateTime? acceptedAt;
  final String? cancelReason;
  final DateTime quoteValidUntil;
  final bool isLocallyPaid;

  OrderResponse copyWith({String? status, bool? isLocallyPaid}) =>
      OrderResponse(
        id: id,
        status: status ?? this.status,
        version: version,
        createdAt: createdAt,
        lines: lines,
        amounts: amounts,
        provider: provider,
        deliveryAddress: deliveryAddress,
        deliveryWindow: deliveryWindow,
        acceptedAt: acceptedAt,
        cancelReason: cancelReason,
        quoteValidUntil: quoteValidUntil,
        isLocallyPaid: isLocallyPaid ?? this.isLocallyPaid,
      );

  factory OrderResponse.fromJson(Map<String, dynamic> json) => OrderResponse(
        id: json['id'] as String,
        status: json['status'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lines: (json['lines'] as List)
            .map((line) => OrderLine.fromJson(line as Map<String, dynamic>))
            .toList(growable: false),
        amounts: QuoteAmounts(
          subtotal: json['subtotal'] as String,
          freight: json['freight'] as String,
          commission: json['commission'] as String,
          total: json['total'] as String,
          providerNet: json['providerNet'] as String,
        ),
        provider: json['provider'] as Map<String, dynamic>?,
        deliveryAddress: json['deliveryAddress'] as String?,
        deliveryWindow:
            DateTime.tryParse(json['deliveryWindow'] as String? ?? ''),
        acceptedAt: DateTime.tryParse(json['acceptedAt'] as String? ?? ''),
        cancelReason: json['cancelReason'] as String?,
        quoteValidUntil: DateTime.parse(json['quoteValidUntil'] as String),
        isLocallyPaid: json['isLocallyPaid'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((line) => line.toJson()).toList(),
        'subtotal': amounts.subtotal,
        'freight': amounts.freight,
        'commission': amounts.commission,
        'total': amounts.total,
        'providerNet': amounts.providerNet,
        'provider': provider,
        'deliveryAddress': deliveryAddress,
        'deliveryWindow': deliveryWindow?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'cancelReason': cancelReason,
        'quoteValidUntil': quoteValidUntil.toIso8601String(),
        'isLocallyPaid': isLocallyPaid,
      };
}

class OrderPage {
  const OrderPage(
      {required this.items, this.nextCursor, this.isFromCache = false});

  final List<OrderResponse> items;
  final String? nextCursor;
  final bool isFromCache;

  factory OrderPage.fromJson(Map<String, dynamic> json) => OrderPage(
        items: (json['items'] as List)
            .map((item) => OrderResponse.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        nextCursor: json['nextCursor'] as String?,
        isFromCache: json['_fromCache'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'nextCursor': nextCursor,
      };
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.id,
    required this.lines,
    required this.deliveryAddress,
    this.deliveryWindow,
  });

  final String id;
  final List<OrderLineInput> lines;
  final String deliveryAddress;
  final DateTime? deliveryWindow;

  Map<String, dynamic> toJson() => {
        'id': id,
        'lines': lines.map((line) => line.toJson()).toList(),
        'deliveryAddress': deliveryAddress.trim(),
        if (deliveryWindow != null)
          'deliveryWindow': deliveryWindow!.toUtc().toIso8601String(),
      };
}

class AcceptQuoteRequest {
  const AcceptQuoteRequest({required this.expectedVersion});
  final int expectedVersion;
  Map<String, dynamic> toJson() => {'expectedVersion': expectedVersion};
}

class CancelOrderRequest {
  const CancelOrderRequest({required this.expectedVersion, this.reason});
  final int expectedVersion;
  final String? reason;
  Map<String, dynamic> toJson() => {
        'expectedVersion': expectedVersion,
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
      };
}
