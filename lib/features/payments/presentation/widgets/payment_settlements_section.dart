import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';
import '../../../home/presentation/home_screen.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/payment_permissions.dart';
import '../providers/payment_backoffice_provider.dart';
import 'mark_settlement_paid_flow.dart';
import 'payment_audit_section.dart';
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
    final isAdmin = PaymentPermissions.canViewAudit(
        ref.watch(homeUserProvider).valueOrNull?.role);
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
                    _SettlementTile(settlement: settlement, isAdmin: isAdmin),
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
  const _SettlementTile({required this.settlement, required this.isAdmin});
  final Settlement settlement;

  /// Solo administración puede consultar quién la marcó pagada.
  final bool isAdmin;

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
            if (settlement.isPaid) ...[
              const SizedBox(height: 6),
              if (isAdmin)
                SettlementPaidBy(settlementId: settlement.id)
              else
                const Text(SettlementStrings.paidByUnavailable,
                    style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
            ],
          ],
        ),
      );
}

/// Quién marcó pagada la liquidación, desde la auditoría (solo admin). Se
/// consulta al tocar el botón, para no hacer una petición por liquidación.
class SettlementPaidBy extends ConsumerStatefulWidget {
  const SettlementPaidBy({super.key, required this.settlementId});
  final String settlementId;

  @override
  ConsumerState<SettlementPaidBy> createState() => _SettlementPaidByState();
}

class _SettlementPaidByState extends ConsumerState<SettlementPaidBy> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    if (!_requested) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: Key('paid-by-${widget.settlementId}'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _requested = true),
          icon: const Icon(Icons.person_search_outlined, size: 18),
          label: const Text(SettlementStrings.showPaidBy),
        ),
      );
    }
    const muted = TextStyle(color: AppTheme.mutedText, fontSize: 13);
    return ref.watch(settlementPaidByProvider(widget.settlementId)).when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Row(children: [
            const Expanded(
                child: Text(SettlementStrings.paidByError, style: muted)),
            TextButton(
              onPressed: () =>
                  ref.invalidate(settlementPaidByProvider(widget.settlementId)),
              child: const Text(CommonStrings.retry),
            ),
          ]),
          data: (entry) => Text(
            entry == null
                ? SettlementStrings.paidByMissing
                : SettlementStrings.paidBy(
                    auditActor(entry).role,
                    auditActor(entry).shortId,
                    AppFormats.bogotaDateTime(entry.at)),
            style: const TextStyle(color: AppTheme.ink, fontSize: 13),
          ),
        );
  }
}
