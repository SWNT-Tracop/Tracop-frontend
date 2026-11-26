import 'payment.dart' show parseMoney;

/// Tipo de transacción contable (`LEDGER_TRANSACTION_KINDS` del backend).
enum LedgerKind {
  paymentVerified('payment_verified'),
  deliveryConfirmed('delivery_confirmed'),
  settlementPaidProducer('settlement_paid_producer'),
  settlementPaidCarrier('settlement_paid_carrier'),
  refund('refund'),

  /// Tipo que esta versión no conoce: se muestra el código tal cual.
  unknown('');

  const LedgerKind(this.wire);
  final String wire;

  static LedgerKind fromWire(String value) => LedgerKind.values.firstWhere(
        (kind) => kind != unknown && kind.wire == value,
        orElse: () => unknown,
      );
}

/// Una línea del libro (`ledgerEntryResponseSchema`). Solo lectura.
class LedgerEntry {
  const LedgerEntry({
    required this.transactionId,
    required this.kind,
    required this.account,
    required this.debit,
    required this.credit,
    required this.createdAt,
    this.rawKind,
  });

  final String transactionId;
  final LedgerKind kind;
  final String account;
  final int debit;
  final int credit;
  final DateTime createdAt;

  /// Tipo tal como llegó del API.
  final String? rawKind;

  String get kindCode =>
      kind == LedgerKind.unknown ? (rawKind ?? '') : kind.wire;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        transactionId: json['transactionId'] as String,
        kind: LedgerKind.fromWire(json['kind'] as String),
        account: json['account'] as String,
        debit: parseMoney(json['debit']),
        credit: parseMoney(json['credit']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        rawKind: json['kind'] as String,
      );
}

/// Líneas de una misma transacción (mismo `transactionId`).
class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.kind,
    required this.kindCode,
    required this.createdAt,
    required this.entries,
  });

  final String id;
  final LedgerKind kind;

  /// Código para el texto (el del API si el tipo es desconocido).
  final String kindCode;
  final DateTime createdAt;
  final List<LedgerEntry> entries;

  int get totalDebit => entries.fold(0, (sum, entry) => sum + entry.debit);
  int get totalCredit => entries.fold(0, (sum, entry) => sum + entry.credit);

  /// Partida doble: la suma de débitos debe igualar la de créditos.
  bool get isBalanced => totalDebit == totalCredit;
}

/// Libro de un pedido agrupado por transacción, en orden cronológico.
class LedgerSummary {
  const LedgerSummary(this.transactions);

  factory LedgerSummary.fromEntries(Iterable<LedgerEntry> entries) {
    final groups = <String, List<LedgerEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.transactionId, () => []).add(entry);
    }
    final transactions = [
      for (final MapEntry(key: id, value: lines) in groups.entries)
        LedgerTransaction(
          id: id,
          kind: lines.first.kind,
          kindCode: lines.first.kindCode,
          createdAt: lines
              .map((line) => line.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          entries: List.unmodifiable(lines),
        ),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return LedgerSummary(List.unmodifiable(transactions));
  }

  final List<LedgerTransaction> transactions;

  bool get isEmpty => transactions.isEmpty;
  int get totalDebit =>
      transactions.fold(0, (sum, transaction) => sum + transaction.totalDebit);
  int get totalCredit =>
      transactions.fold(0, (sum, transaction) => sum + transaction.totalCredit);

  /// Cuadra si el total cuadra y además cada transacción cuadra por sí sola.
  bool get isBalanced =>
      totalDebit == totalCredit &&
      transactions.every((transaction) => transaction.isBalanced);

  /// Diferencia absoluta entre débitos y créditos del total.
  int get difference => (totalDebit - totalCredit).abs();
}
