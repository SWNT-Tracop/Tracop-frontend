import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/settlement_filters.dart';
import '../payment_error_text.dart';
import '../providers/payment_backoffice_provider.dart';
import '../widgets/mark_settlement_paid_flow.dart';
import '../widgets/payment_states.dart';
import '../widgets/settlement_filters_bar.dart';
import '../widgets/settlement_table.dart';

/// Liquidaciones a productores y transportistas (finance, operator, admin).
class SettlementsScreen extends ConsumerStatefulWidget {
  const SettlementsScreen({
    super.key,
    this.initialStatus = SettlementStatusFilter.issued,
    this.initialQuery = '',
    this.clock,
  });

  final SettlementStatusFilter initialStatus;

  /// Búsqueda inicial; el detalle del pago la usa con el id del pago.
  final String initialQuery;

  /// Reloj inyectable para los filtros de periodo en pruebas.
  final DateTime Function()? clock;

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  late SettlementStatusFilter _status = widget.initialStatus;
  late SettlementFilters _filters =
      SettlementFilters(query: widget.initialQuery);

  void _refresh() {
    ref.invalidate(settlementsProvider(_status));
    ref.invalidate(paymentsMetricsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settlementsProvider(_status));
    final items = async.valueOrNull;
    final textTheme = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await ref
            .read(settlementsProvider(_status).future)
            .catchError((_) => const <Settlement>[]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SettlementStrings.title,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(SettlementStrings.intro, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: async.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text(PaymentStrings.refresh),
            ),
          ]),
          const SizedBox(height: 16),
          SettlementFiltersBar(
            status: _status,
            filters: _filters,
            onStatusChanged: (value) => setState(() => _status = value),
            onChanged: (value) => setState(() => _filters = value),
          ),
          const SizedBox(height: 16),
          if (async.isLoading && items == null)
            const PaymentLoadingSkeleton(rows: 4)
          else if (async.hasError && items == null)
            PaymentErrorState(
              title: SettlementStrings.loadError,
              message: async.error is DomainFailure
                  ? settlementErrorText(async.error! as DomainFailure)
                  : SettlementStrings.loadError,
              onRetry: _refresh,
            )
          else
            ..._results(items ?? const [], async.hasError),
        ],
      ),
    );
  }

  /// Liquidaciones por pagar que existen (según las métricas) pero no
  /// llegaron: el API ordena por `issuedAt` descendente y corta en 100, así
  /// que las más antiguas quedan fuera.
  int _hiddenIssued(List<Settlement> all) {
    if (_status == SettlementStatusFilter.paid) return 0;
    final metrics = ref.watch(paymentsMetricsProvider).valueOrNull;
    if (metrics == null) return 0;
    final loaded =
        all.where((item) => item.status == SettlementStatus.issued).length;
    final hidden = metrics.settlementsIssued.count - loaded;
    return hidden > 0 ? hidden : 0;
  }

  List<Widget> _results(List<Settlement> all, bool staleError) {
    final hidden = _hiddenIssued(all);
    final alert = [
      if (hidden > 0) ...[
        HiddenIssuedAlert(count: hidden),
        const SizedBox(height: 12),
      ],
    ];
    if (all.isEmpty) {
      return [
        ...alert,
        PaymentEmptyState(
          icon: Icons.task_alt,
          title: SettlementStrings.emptyTitle,
          body: _status == SettlementStatusFilter.issued
              ? SettlementStrings.emptyIssuedBody
              : SettlementStrings.emptyBody,
        ),
      ];
    }
    final visible = _filters.apply(all, (widget.clock ?? DateTime.now)());
    final muted = Theme.of(context).textTheme.bodySmall;
    return [
      ...alert,
      if (staleError)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(SettlementStrings.loadError,
              style: TextStyle(color: AppTheme.dangerStrong)),
        ),
      Text(
        [
          SettlementStrings.resultsCount(visible.length, all.length),
          if (all.length >= PaymentBackofficeLimits.settlements)
            SettlementStrings.limitNote,
        ].join(' · '),
        style: muted,
      ),
      const SizedBox(height: 8),
      if (visible.isEmpty)
        PaymentEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: SettlementStrings.noMatchesTitle,
          body: SettlementStrings.noMatchesBody,
          action: OutlinedButton(
            onPressed: () =>
                setState(() => _filters = const SettlementFilters()),
            child: const Text(PaymentStrings.clearFilters),
          ),
        )
      else
        SettlementTable(
          settlements: visible,
          onOpenPayment: (settlement) => context
              .push('/pagos/${settlement.paymentId}?desde=liquidaciones'),
          onMarkPaid: (settlement) =>
              runMarkSettlementPaid(context, ref, settlement),
        ),
    ];
  }
}

/// Aviso de liquidaciones por pagar que el servidor no entregó.
class HiddenIssuedAlert extends StatelessWidget {
  const HiddenIssuedAlert({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('hidden-issued-alert'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.dangerSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SettlementStrings.hiddenIssued(count),
                    style: const TextStyle(
                        color: AppTheme.dangerText,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(SettlementStrings.hiddenIssuedHelp,
                    style: TextStyle(color: AppTheme.dangerText)),
              ],
            ),
          ),
        ]),
      );
}
