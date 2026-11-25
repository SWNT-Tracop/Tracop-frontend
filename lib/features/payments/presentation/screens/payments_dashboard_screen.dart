import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/config/payment_config.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/payments_metrics.dart';
import '../payment_error_text.dart';
import '../providers/payment_backoffice_provider.dart';
import '../widgets/payment_states.dart';

/// Resumen de pagos del personal: se entiende en 30 segundos. Tarjetas con
/// lo que requiere atención, una barra pagado vs por pagar y accesos
/// directos. Primer destino del personal.
class PaymentsDashboardScreen extends ConsumerWidget {
  const PaymentsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentsMetricsProvider);
    final metrics = async.valueOrNull;
    final textTheme = Theme.of(context).textTheme;
    void refresh() => ref.invalidate(paymentsMetricsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        refresh();
        await ref
            .read(paymentsMetricsProvider.future)
            .then<void>((_) {}, onError: (_) {});
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PaymentsDashboardStrings.title,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(PaymentsDashboardStrings.intro,
                      style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: async.isLoading ? null : refresh,
              icon: const Icon(Icons.refresh),
              label: const Text(PaymentStrings.refresh),
            ),
          ]),
          if (metrics != null) ...[
            const SizedBox(height: 6),
            Text(
              '${PaymentsDashboardStrings.updated(AppFormats.bogotaDateTime(metrics.generatedAt))}'
              ' · ${PaymentStrings.bogotaTimeNote}',
              style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
          ],
          const SizedBox(height: 16),
          if (async.isLoading && metrics == null)
            const PaymentLoadingSkeleton(rows: 4)
          else if (async.hasError && metrics == null)
            PaymentErrorState(
              title: PaymentsDashboardStrings.loadError,
              message: async.error is DomainFailure
                  ? paymentErrorText(async.error! as DomainFailure)
                  : PaymentsDashboardStrings.loadError,
              onRetry: refresh,
            )
          else if (metrics != null) ...[
            if (async.hasError)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(PaymentsDashboardStrings.loadError,
                    style: TextStyle(color: AppTheme.dangerStrong)),
              ),
            PaymentsDashboard(metrics: metrics),
          ],
        ],
      ),
    );
  }
}

/// Contenido del resumen; separado para probarlo sin providers.
class PaymentsDashboard extends StatelessWidget {
  const PaymentsDashboard({
    super.key,
    required this.metrics,
    this.overdueHours = PaymentConfig.reviewOverdueHours,
  });

  final PaymentsMetrics metrics;
  final int overdueHours;

  @override
  Widget build(BuildContext context) {
    final age = metrics.oldestProofAge;
    final overdue = metrics.oldestProofOverdue(overdueHours);
    final ageText = age == null ? null : PaymentStrings.waiting(age);
    void go(String location) => context.go(location);

    final cards = <Widget>[
      MetricCard(
        key: const Key('metric-proofs'),
        icon: Icons.fact_check_outlined,
        label: PaymentsDashboardStrings.proofs,
        value: '${metrics.proofsAwaitingReview}',
        detail: ageText == null
            ? PaymentsDashboardStrings.noneWaiting
            : PaymentsDashboardStrings.oldest(ageText),
        tone: overdue ? MetricTone.alert : MetricTone.normal,
        actionLabel: PaymentsDashboardStrings.reviewProofs,
        onAction: () => go('/pagos/revision?filtro=comprobantes'),
      ),
      MetricCard(
        key: const Key('metric-disputes'),
        icon: Icons.report_gmailerrorred_outlined,
        label: PaymentsDashboardStrings.disputes,
        value: '${metrics.openDisputes}',
        tone: metrics.openDisputes > 0 ? MetricTone.warning : MetricTone.normal,
        actionLabel: PaymentsDashboardStrings.reviewDisputes,
        onAction: () => go('/pagos/revision?filtro=disputas'),
      ),
      MetricCard(
        key: const Key('metric-issued'),
        icon: Icons.schedule,
        label: PaymentsDashboardStrings.issued,
        value: AppFormats.cop(metrics.settlementsIssued.amountCop),
        detail: PaymentsDashboardStrings.settlementsCount(
            metrics.settlementsIssued.count),
        tone: metrics.settlementsIssued.count > 0
            ? MetricTone.warning
            : MetricTone.normal,
        actionLabel: PaymentsDashboardStrings.openIssued,
        onAction: () => go('/pagos/liquidaciones?estado=emitidas'),
      ),
      MetricCard(
        key: const Key('metric-paid'),
        icon: Icons.task_alt,
        label: PaymentsDashboardStrings.paid,
        value: AppFormats.cop(metrics.settlementsPaid.amountCop),
        detail: PaymentsDashboardStrings.settlementsCount(
            metrics.settlementsPaid.count),
        actionLabel: PaymentsDashboardStrings.openPaid,
        onAction: () => go('/pagos/liquidaciones?estado=pagadas'),
      ),
      MetricCard(
        key: const Key('metric-paid-orders'),
        icon: Icons.receipt_long_outlined,
        label: PaymentsDashboardStrings.paidOrders,
        value: AppFormats.cop(metrics.paidOrdersTotalCop),
        detail: PaymentsDashboardStrings.paidOrdersHint,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overdue && ageText != null) ...[
          _OverdueAlert(
            text: PaymentsDashboardStrings.overdueAlert(
                metrics.proofsAwaitingReview, overdueHours, ageText),
            onAction: () => go('/pagos/revision?filtro=comprobantes'),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 560
                  ? 2
                  : 1;
          const gap = 12.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ]);
        }),
        const SizedBox(height: 16),
        SettlementBalanceBar(
          paid: metrics.settlementsPaid.amountCop,
          issued: metrics.settlementsIssued.amountCop,
          issuedCount: metrics.settlementsIssued.count,
        ),
      ],
    );
  }
}

enum MetricTone { normal, warning, alert }

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.tone = MetricTone.normal,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final MetricTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (accent, surface) = switch (tone) {
      MetricTone.alert => (AppTheme.dangerText, AppTheme.dangerSurface),
      MetricTone.warning => (AppTheme.warningText, AppTheme.warningSurface),
      MetricTone.normal => (AppTheme.forest, AppTheme.mint),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ]),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      color: tone == MetricTone.normal ? AppTheme.ink : accent,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(detail!,
                  style: TextStyle(
                      color: tone == MetricTone.alert
                          ? AppTheme.dangerText
                          : AppTheme.mutedText,
                      fontWeight: tone == MetricTone.alert
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverdueAlert extends StatelessWidget {
  const _OverdueAlert({required this.text, required this.onAction});
  final String text;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('overdue-alert'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.dangerSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerText),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.dangerText, fontWeight: FontWeight.w600)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dangerStrong),
              onPressed: onAction,
              child: const Text(PaymentsDashboardStrings.reviewProofs),
            ),
          ],
        ),
      );
}

/// Barra horizontal pagado vs por pagar hecha con widgets simples (sin
/// dependencias de gráficos).
class SettlementBalanceBar extends StatelessWidget {
  const SettlementBalanceBar({
    super.key,
    required this.paid,
    required this.issued,
    this.issuedCount = 0,
  });
  final int paid;
  final int issued;
  final int issuedCount;

  /// Ancho mínimo (en milésimas) de un segmento con monto mayor que cero,
  /// para que un pendiente pequeño no desaparezca de la barra.
  static const minSegment = 40;

  /// Reparto de la barra en milésimas `(pagado, por pagar)`.
  static (int, int) segments(int paid, int issued) {
    final total = paid + issued;
    if (total <= 0) return (0, 0);
    var paidFlex = (paid / total * 1000).round();
    if (issued > 0 && 1000 - paidFlex < minSegment) {
      paidFlex = 1000 - minSegment;
    }
    if (paid > 0 && paidFlex < minSegment) paidFlex = minSegment;
    return (paidFlex, 1000 - paidFlex);
  }

  @override
  Widget build(BuildContext context) {
    final total = paid + issued;
    final textTheme = Theme.of(context).textTheme;
    // Proporción en double solo para dibujar; los montos siguen siendo int.
    final paidRatio = total <= 0 ? 0.0 : paid / total;
    final (paidFlex, issuedFlex) = segments(paid, issued);
    final paidPercent = (paidRatio * 100).round();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(PaymentsDashboardStrings.barTitle,
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (total <= 0)
              Text(PaymentsDashboardStrings.barEmpty,
                  style: textTheme.bodyMedium)
            else ...[
              Semantics(
                label: PaymentsDashboardStrings.barSemantics(
                    AppFormats.cop(paid), AppFormats.cop(issued)),
                child: Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 22,
                        child: Row(children: [
                          if (paidFlex > 0)
                            Expanded(
                                key: const Key('bar-paid'),
                                flex: paidFlex,
                                child: Container(color: AppTheme.primary)),
                          if (issuedFlex > 0)
                            Expanded(
                                key: const Key('bar-issued'),
                                flex: issuedFlex,
                                child: Container(color: AppTheme.warningIcon)),
                        ]),
                      ),
                    ),
                  ),
                  if (issuedCount > 0) ...[
                    const SizedBox(width: 10),
                    Text(PaymentsDashboardStrings.pendingCount(issuedCount),
                        style: const TextStyle(
                            color: AppTheme.warningText,
                            fontWeight: FontWeight.w700)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 24, runSpacing: 8, children: [
                _Legend(
                  color: AppTheme.primary,
                  label: PaymentsDashboardStrings.legendPaid,
                  amount: AppFormats.cop(paid),
                  percent: PaymentsDashboardStrings.percent(paidPercent),
                ),
                _Legend(
                  color: AppTheme.warningIcon,
                  label: PaymentsDashboardStrings.legendIssued,
                  amount: AppFormats.cop(issued),
                  percent: PaymentsDashboardStrings.percent(100 - paidPercent),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
  });

  final Color color;
  final String label;
  final String amount;
  final String percent;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$label ',
                  style: const TextStyle(color: AppTheme.mutedText)),
              TextSpan(
                  text: amount,
                  style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()])),
              TextSpan(
                  text: ' · $percent',
                  style: const TextStyle(color: AppTheme.mutedText)),
            ])),
          ),
        ],
      );
}
