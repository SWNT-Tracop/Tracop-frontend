import 'payment.dart' show parseMoney;

/// Largo máximo de la referencia de pago (`markSettlementPaidSchema`).
const maxSettlementReferenceLength = 100;

/// Estado de una liquidación (`settlementStatusSchema`).
enum SettlementStatus {
  issued('issued'),
  paid('paid'),

  /// Estado que esta versión no conoce: se muestra sin "Marcar pagada".
  unknown('');

  const SettlementStatus(this.wire);
  final String wire;

  static SettlementStatus fromWire(String value) =>
      SettlementStatus.values.firstWhere(
        (status) => status != unknown && status.wire == value,
        orElse: () => unknown,
      );
}

/// A quién se le paga la liquidación. `producer` es el proveedor del pedido
/// (productor o proveedor), según el backend.
enum BeneficiaryKind {
  producer('producer'),
  carrier('carrier'),

  /// Tipo que esta versión no conoce: se muestra el código tal cual.
  unknown('');

  const BeneficiaryKind(this.wire);
  final String wire;

  /// Tipos que se pueden filtrar.
  static const selectable = [producer, carrier];

  static BeneficiaryKind fromWire(String value) =>
      BeneficiaryKind.values.firstWhere(
        (kind) => kind != unknown && kind.wire == value,
        orElse: () => unknown,
      );
}

/// Liquidación de un pago a un beneficiario (`settlementResponseSchema`).
///
/// El API no expone quién la marcó como pagada (`paidBy` vive solo en el
/// servidor y en la auditoría); la app muestra `reference` y `paidAt`.
class Settlement {
  const Settlement({
    required this.id,
    required this.paymentId,
    required this.orderId,
    required this.beneficiaryId,
    required this.beneficiaryKind,
    required this.amount,
    required this.status,
    required this.issuedAt,
    required this.paidAt,
    required this.reference,
    required this.version,
    this.rawBeneficiaryKind,
    this.rawStatus,
  });

  final String id;
  final String paymentId;
  final String orderId;
  final String beneficiaryId;
  final BeneficiaryKind beneficiaryKind;
  final int amount;
  final SettlementStatus status;
  final DateTime issuedAt;
  final DateTime? paidAt;
  final String? reference;
  final int version;

  /// Valores tal como llegaron del API (para mostrar los desconocidos).
  final String? rawBeneficiaryKind;
  final String? rawStatus;

  String get beneficiaryKindCode => beneficiaryKind == BeneficiaryKind.unknown
      ? (rawBeneficiaryKind ?? '')
      : beneficiaryKind.wire;
  String get statusCode =>
      status == SettlementStatus.unknown ? (rawStatus ?? '') : status.wire;

  bool get isPaid => status == SettlementStatus.paid;

  /// Solo una liquidación emitida (estado conocido) se puede marcar pagada.
  bool get canMarkPaid => status == SettlementStatus.issued;

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'] as String,
        paymentId: json['paymentId'] as String,
        orderId: json['orderId'] as String,
        beneficiaryId: json['beneficiaryId'] as String,
        beneficiaryKind:
            BeneficiaryKind.fromWire(json['beneficiaryKind'] as String),
        amount: parseMoney(json['amount']),
        status: SettlementStatus.fromWire(json['status'] as String),
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        paidAt: json['paidAt'] is String
            ? DateTime.parse(json['paidAt'] as String)
            : null,
        reference: json['reference'] as String?,
        version: json['version'] as int,
        rawBeneficiaryKind: json['beneficiaryKind'] as String,
        rawStatus: json['status'] as String,
      );
}
