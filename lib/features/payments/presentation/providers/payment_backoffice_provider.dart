import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/payments_metrics.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/repository/payment_backoffice_repository.dart';
import '../../domain/settlement_filters.dart';
import 'payment_provider.dart';

abstract final class PaymentBackofficeLimits {
  /// Máximo de `GET /settlements` (`limit` 1..100).
  static const settlements = 100;
}

final paymentBackofficeRepositoryProvider =
    Provider<PaymentBackofficeRepository>((ref) {
  throw UnimplementedError(
      'PaymentBackofficeRepository requires its remote data source setup.');
});

/// Liquidaciones según el filtro de estado del servidor.
final settlementsProvider = FutureProvider.autoDispose
    .family<List<Settlement>, SettlementStatusFilter>((ref, filter) async {
  ref.watch(authProvider);
  final result = await ref
      .read(paymentBackofficeRepositoryProvider)
      .settlements(status: filter.status);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

/// Liquidaciones de un pago. El API no filtra por pago: se piden las 100
/// más recientes y se filtran en el cliente (ver payments-decisions.md).
final paymentSettlementsProvider = FutureProvider.autoDispose
    .family<List<Settlement>, String>((ref, paymentId) async {
  final all =
      await ref.watch(settlementsProvider(SettlementStatusFilter.all).future);
  return all.where((item) => item.paymentId == paymentId).toList();
});

/// Libro contable del pedido agrupado por transacción.
final orderLedgerProvider = FutureProvider.autoDispose
    .family<LedgerSummary, String>((ref, orderId) async {
  ref.watch(authProvider);
  final result = await ref
      .read(paymentBackofficeRepositoryProvider)
      .ledgerForOrder(orderId);
  return result.map(
      ok: (value) => LedgerSummary.fromEntries(value.value),
      err: (failure) => throw failure.error);
});

final paymentsMetricsProvider =
    FutureProvider.autoDispose<PaymentsMetrics>((ref) async {
  ref.watch(authProvider);
  final result = await ref.read(paymentBackofficeRepositoryProvider).metrics();
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

/// Tras marcar una liquidación se recargan las vistas que dependen de ella:
/// listas, métricas, libro y el pago (puede quedar `settled`).
void invalidateAfterSettlementChange(WidgetRef ref) {
  ref.invalidate(settlementsProvider);
  ref.invalidate(paymentSettlementsProvider);
  ref.invalidate(paymentsMetricsProvider);
  ref.invalidate(orderLedgerProvider);
  ref.invalidate(paymentDetailProvider);
}
