/// Entrada del audit log del personal (`GET /backoffice/audit`, solo admin).
///
/// Solo se leen los campos que usa la app; campos nuevos se ignoran y
/// `before`/`after` que no sean objetos se tratan como ausentes.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.before,
    required this.after,
    required this.at,
  });

  final String id;

  /// `null` cuando la acción la hizo el sistema.
  final String? actorId;
  final String actorRole;
  final String action;
  final String entity;
  final String entityId;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime at;

  /// Estado anterior/posterior si la entrada lo registra como texto.
  String? get beforeStatus => _status(before);
  String? get afterStatus => _status(after);

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id'] as String,
        actorId: json['actorId'] as String?,
        actorRole: json['actorRole'] as String? ?? '',
        action: json['action'] as String? ?? '',
        entity: json['entity'] as String? ?? '',
        entityId: json['entityId'] as String? ?? '',
        before: _map(json['before']),
        after: _map(json['after']),
        at: DateTime.parse(json['at'] as String),
      );
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

String? _status(Map<String, dynamic>? value) {
  final status = value?['status'];
  return status is String && status.isNotEmpty ? status : null;
}

/// Página del audit log; `nextCursor == null` significa que no hay más.
class AuditPage {
  const AuditPage({required this.items, this.nextCursor});
  final List<AuditEntry> items;
  final String? nextCursor;

  factory AuditPage.fromJson(Map<String, dynamic> json) => AuditPage(
        items: (json['items'] as List)
            .map((item) =>
                AuditEntry.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(growable: false),
        nextCursor: json['nextCursor'] is String &&
                (json['nextCursor'] as String).isNotEmpty
            ? json['nextCursor'] as String
            : null,
      );
}

/// Entidades y acciones que registra payments-service.
abstract final class AuditTargets {
  static const payment = 'payment';
  static const settlement = 'settlement';
  static const settlementMarkPaid = 'settlement.mark_paid';
}
