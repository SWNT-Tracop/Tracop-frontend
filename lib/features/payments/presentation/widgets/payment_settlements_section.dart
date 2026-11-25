import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/settlement.dart';
import '../providers/payment_backoffice_provider.dart';
import 'mark_settlement_paid_flow.dart';
import 'payment_states.dart';
import 'settlement_badges.dart';

/// Liquidaciones del pago dentro de su detalle, con enlace a la lista
/// filtrada por este pago.
class PaymentSettlementsSection extends ConsumerWidget {
  const PaymentSettlementsSection(
      {super.key, required this.paymentId, required this.status});
  final String paymentId;

  /// Estado del pago: explica por qué puede no haber liquidaciones.
  final PaymentStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentSettlementsProvider(paymentId));
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Text(SettlementStrings.paymentSectionTitle,
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          TextButton.icon(
            onPressed: () => context
                .push('/pagos/liquidaciones?estado=todas&pago=$paymentId'),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text(SettlementStrings.viewInSettlements),
          ),
        ]),
        const SizedBox(height: 8),
        async.when(
          skipLoadingOnReload: true,
          loading: () => const PaymentLoadingSkeleton(rows: 1),
          error: (_, __) => PaymentErrorState(
            title: SettlementStrings.paymentSectionError,
            message: SettlementStrings.loadError,
            onRetry: () => ref.invalidate(paymentSettlementsProvider),
          ),
          data: (items) => items.isEmpty
              ? _Empty(status: status)
              : Column(children: [
                  for (final settlement in items)
                    _SettlementTile(settlement: settlement),
                ]),
        ),
      ],
    );
  }
}

/// Sin liquidaciones: en `held` aún no se emiten (ventana de reclamo); en
/// `settled` existen pero quedaron fuera de las 100 que entrega el API.
class _Empty extends StatelessWidget {
  const _Empty({required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (status) {
      PaymentStatus.held => (
          Icons.schedule,
          SettlementStrings.heldNotIssuedYet
        ),
      PaymentStatus.settled => (
          Icons.manage_search,
          SettlementStrings.settledOutOfRange
        ),
      _ => (Icons.info_outline, SettlementStrings.paymentSectionEmpty),
    };
    return Container(
      key: Key('settlements-empty-${status.wire}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.mutedText),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text, style: const TextStyle(color: AppTheme.ink))),
      ]),
    );
  }
}

class _SettlementTile extends ConsumerWidget {
  const _SettlementTile({required this.settlement});
  final Settlement settlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outline),
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: BeneficiaryLabel(settlement: settlement)),
              Text(AppFormats.cop(settlement.amount),
                  style: const TextStyle(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SettlementStatusBadge(
                    status: settlement.status, wire: settlement.statusCode),
                if (settlement.paidAt != null)
                  Text(SettlementStrings.paidOn(
                      AppFormats.bogotaDateTime(settlement.paidAt!))),
                if (!settlement.canMarkPaid)
                  Text('${SettlementStrings.columnReference}: '
                      '${settlement.reference ?? SettlementStrings.noReference}'),
                if (settlement.canMarkPaid)
                  FilledButton.tonal(
                    onPressed: () =>
                        runMarkSettlementPaid(context, ref, settlement),
                    child: const Text(SettlementStrings.markPaid),
                  ),
              ],
            ),
          ],
        ),
      );
}
