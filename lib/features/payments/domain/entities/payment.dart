/// Estado del pago tal como lo expone el API (`paymentStatusSchema`).
enum PaymentStatus {
  pending('pending'),
  proofUploaded('proof_uploaded'),
  verified('verified'),
  held('held'),
  settled('settled'),
  rejected('rejected'),
  disputed('disputed'),
  refunded('refunded'),

  /// Valor que esta versión de la app no conoce: se muestra con estilo
  /// neutro y sin acciones, en vez de romper la pantalla.
  unknown('');

  const PaymentStatus(this.wire);
  final String wire;

  static PaymentStatus fromWire(String value) =>
      PaymentStatus.values.firstWhere(
        (status) => status != unknown && status.wire == value,
        orElse: () => unknown,
      );

  /// Estados que ya no cambian.
  bool get isFinal => this == settled || this == rejected || this == refunded;
}

enum PaymentMethod {
  transfer('transfer'),
  nequi('nequi'),

  /// Medio que esta versión de la app no conoce (solo para mostrar).
  unknown('');

  const PaymentMethod(this.wire);
  final String wire;

  /// Medios que se pueden elegir o filtrar.
  static const selectable = [transfer, nequi];

  static PaymentMethod fromWire(String value) =>
      PaymentMethod.values.firstWhere(
        (method) => method != unknown && method.wire == value,
        orElse: () => unknown,
      );
}

enum DisputeOutcome {
  release('release'),
  refund('refund');

  const DisputeOutcome(this.wire);
  final String wire;
}

/// Pago de un pedido. Los montos son enteros en COP (el API los envía como
/// texto para no perder precisión); nunca se convierten a `double`.
///
/// `proofUrl` es una URL firmada de corta duración: solo vive en memoria. Esta
/// clase no tiene `toJson` a propósito, para que no termine en caché, y
/// `toString` la oculta para que no aparezca en registros.
class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.version,
    required this.subtotal,
    required this.freight,
    required this.commission,
    required this.total,
    required this.providerNet,
    required this.proofUploadedAt,
    required this.proofUrl,
    required this.reviewedAt,
    required this.rejectionReason,
    required this.heldAt,
    required this.disputeReason,
    required this.createdAt,
    required this.updatedAt,
    this.rawStatus,
    this.rawMethod,
  });

  final String id;
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final int version;
  final int subtotal;
  final int freight;
  final int commission;
  final int total;
  final int providerNet;
  final DateTime? proofUploadedAt;
  final String? proofUrl;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? heldAt;
  final String? disputeReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Valores tal como llegaron del API (para mostrar los desconocidos).
  final String? rawStatus;
  final String? rawMethod;

  /// Código del estado para textos: el del API si la app no lo conoce.
  String get statusCode =>
      status == PaymentStatus.unknown ? (rawStatus ?? '') : status.wire;
  String get methodCode =>
      method == PaymentMethod.unknown ? (rawMethod ?? '') : method.wire;

  bool get hasProof => proofUploadedAt != null;

  /// Momento desde el que el pago espera revisión del personal.
  DateTime get waitingSince => switch (status) {
        PaymentStatus.proofUploaded => proofUploadedAt ?? updatedAt,
        _ => updatedAt,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        method: PaymentMethod.fromWire(json['method'] as String),
        status: PaymentStatus.fromWire(json['status'] as String),
        version: json['version'] as int,
        subtotal: parseMoney(json['subtotal']),
        freight: parseMoney(json['freight']),
        commission: parseMoney(json['commission']),
        total: parseMoney(json['total']),
        providerNet: parseMoney(json['providerNet']),
        proofUploadedAt: _date(json['proofUploadedAt']),
        proofUrl: json['proofUrl'] as String?,
        reviewedAt: _date(json['reviewedAt']),
        rejectionReason: json['rejectionReason'] as String?,
        heldAt: _date(json['heldAt']),
        disputeReason: json['disputeReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        rawStatus: json['status'] as String,
        rawMethod: json['method'] as String,
      );

  @override
  String toString() => 'Payment(id: $id, orderId: $orderId, '
      'status: ${status.wire}, version: $version, '
      'proofUrl: ${proofUrl == null ? 'null' : '<oculta>'})';
}

/// Montos del API: enteros sin signo en texto (`^(0|[1-9]\d{0,18})$`).
int parseMoney(Object? value) {
  if (value is int) return value;
  if (value is String && RegExp(r'^(0|[1-9]\d{0,18})$').hasMatch(value)) {
    return int.parse(value);
  }
  throw const FormatException('Monto inválido.');
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value) : null;

/// Autorización de carga directa al almacenamiento (POST prefirmado).
class ProofUploadPolicy {
  const ProofUploadPolicy({
    required this.url,
    required this.fields,
    required this.expiresAt,
  });

  final String url;
  final Map<String, String> fields;
  final DateTime expiresAt;

  factory ProofUploadPolicy.fromJson(Map<String, dynamic> json) {
    final policy = Map<String, dynamic>.from(json['uploadPolicy'] as Map);
    return ProofUploadPolicy(
      url: policy['url'] as String,
      fields: Map<String, String>.from(policy['fields'] as Map),
      expiresAt: DateTime.parse(policy['expiresAt'] as String),
    );
  }

  @override
  String toString() => 'ProofUploadPolicy(expiresAt: $expiresAt)';
}

/// Archivo de comprobante ya leído en memoria y validado.
class ProofFile {
  const ProofFile({
    required this.bytes,
    required this.filename,
    required this.format,
  });

  final List<int> bytes;
  final String filename;
  final ProofImageFormat format;
}

enum ProofImageFormat { jpeg, png, webp }

/// Hito del pago derivado de las marcas de tiempo que trae el API. No existe
/// un endpoint de historial: solo se muestran los hitos que el pago registra.
class PaymentMilestone {
  const PaymentMilestone({required this.kind, required this.at});
  final PaymentMilestoneKind kind;
  final DateTime? at;
}

enum PaymentMilestoneKind {
  created,
  proofUploaded,
  verified,
  rejected,
  held,
  disputed,
  current,
}

List<PaymentMilestone> paymentMilestones(Payment payment) {
  final items = <PaymentMilestone>[
    PaymentMilestone(kind: PaymentMilestoneKind.created, at: payment.createdAt),
    if (payment.proofUploadedAt != null)
      PaymentMilestone(
          kind: PaymentMilestoneKind.proofUploaded,
          at: payment.proofUploadedAt),
    if (payment.reviewedAt != null)
      PaymentMilestone(
        kind: payment.status == PaymentStatus.rejected
            ? PaymentMilestoneKind.rejected
            : PaymentMilestoneKind.verified,
        at: payment.reviewedAt,
      ),
    if (payment.heldAt != null)
      PaymentMilestone(kind: PaymentMilestoneKind.held, at: payment.heldAt),
    // El API guarda el motivo de la disputa pero no su fecha.
    if (payment.disputeReason != null)
      const PaymentMilestone(kind: PaymentMilestoneKind.disputed, at: null),
    PaymentMilestone(kind: PaymentMilestoneKind.current, at: payment.updatedAt),
  ];
  return items;
}
