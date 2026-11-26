import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/config/payment_config.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/review_filters.dart';
import '../payment_error_text.dart';
import '../providers/payment_backoffice_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_filters.dart';
import '../widgets/payment_states.dart';
import '../widgets/payment_table.dart';

/// Bandeja de revisión del personal (finance, operator, admin).
class PaymentReviewInboxScreen extends ConsumerStatefulWidget {
  const PaymentReviewInboxScreen(
      {super.key, this.clock, this.initialFilters = const ReviewFilters()});

  /// Filtros iniciales (p. ej. desde los accesos del resumen de pagos).
  final ReviewFilters initialFilters;

  /// Reloj inyectable para pruebas del indicador de atraso.
  final DateTime Function()? clock;

  @override
  ConsumerState<PaymentReviewInboxScreen> createState() =>
      _PaymentReviewInboxScreenState();
}

class _PaymentReviewInboxScreenState
    extends ConsumerState<PaymentReviewInboxScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  late ReviewFilters _filters = widget.initialFilters;
  DateTime? _lastRefresh;
  bool _appVisible = true;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(PaymentConfig.reviewAutoRefresh, (_) {
      // Solo mientras la pantalla está visible: app en primer plano y sin
      // otra ruta o diálogo encima (evita recargar bajo un diálogo abierto).
      if (!mounted || !_appVisible) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(paymentReviewQueueProvider);
    // Las métricas dicen cuántos pendientes hay en total (aviso de corte).
    ref.invalidate(paymentsMetricsProvider);
  }

  void _open(Payment payment) => context.push('/pagos/${payment.id}');

  @override
  Widget build(BuildContext context) {
    ref.listen(paymentReviewQueueProvider, (_, next) {
      // Solo cuenta como actualización una carga exitosa.
      if (next.hasValue && !next.isLoading && !next.hasError) {
        setState(() => _lastRefresh = _now());
      }
    });
    final queue = ref.watch(paymentReviewQueueProvider);
    final textTheme = Theme.of(context).textTheme;
    final now = _now();
    final items = queue.valueOrNull;

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await ref.read(paymentReviewQueueProvider.future).catchError((_) {
          return const <Payment>[];
        });
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PaymentStrings.reviewTitle,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(PaymentStrings.reviewIntro, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: queue.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text(PaymentStrings.refresh),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            [
              if (_lastRefresh != null)
                PaymentStrings.lastRefresh(
                    AppFormats.bogotaTime(_lastRefresh!)),
              PaymentStrings.autoRefreshNote,
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 16),
          PaymentFilters(
            filters: _filters,
            onChanged: (value) => setState(() => _filters = value),
          ),
          const SizedBox(height: 16),
          if (queue.isLoading && items == null)
            const PaymentLoadingSkeleton(rows: 4)
          else if (queue.hasError && items == null)
            PaymentErrorState(
              title: PaymentStrings.reviewLoadError,
              message: queue.error is DomainFailure
                  ? paymentErrorText(queue.error! as DomainFailure)
                  : PaymentStrings.reviewLoadError,
              onRetry: _refresh,
            )
          else
            ..._results(items ?? const [], now),
        ],
      ),
    );
  }

  /// Pendientes que el servidor no entregó: `GET /payments/review` corta en
  /// 100 ordenando por `updatedAt` ascendente, así que quedan fuera los más
  /// recientes. `null` = sin aviso; `0` = posible corte sin cifra exacta.
  /// Below the limit the queue is complete: queue and metrics are separate
  /// requests, so a gap between them must not be reported as hidden items.
  int? _hiddenPending(int loaded) {
    if (loaded < PaymentConfig.reviewQueueLimit) return null;
    final metrics = ref.watch(paymentsMetricsProvider).valueOrNull;
    final total = metrics == null
        ? null
        : metrics.proofsAwaitingReview + metrics.openDisputes;
    return total != null && total > loaded ? total - loaded : 0;
  }

  List<Widget> _results(List<Payment> all, DateTime now) {
    if (all.isEmpty) {
      return const [
        PaymentEmptyState(
          icon: Icons.task_alt,
          title: PaymentStrings.reviewEmptyTitle,
          body: PaymentStrings.reviewEmptyBody,
        ),
      ];
    }
    final visible = _filters.apply(all);
    final hidden = _hiddenPending(all.length);
    return [
      if (hidden != null) ...[
        ReviewHiddenAlert(count: hidden),
        const SizedBox(height: 12),
      ],
      if (ref.watch(paymentReviewQueueProvider).hasError)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(PaymentStrings.reviewLoadError,
              style: TextStyle(color: AppTheme.dangerStrong)),
        ),
      Text(PaymentStrings.resultsCount(visible.length, all.length),
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      if (visible.isEmpty)
        PaymentEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: PaymentStrings.reviewNoMatchesTitle,
          body: PaymentStrings.reviewNoMatchesBody,
          action: OutlinedButton(
            onPressed: () => setState(() => _filters = const ReviewFilters()),
            child: const Text(PaymentStrings.clearFilters),
          ),
        )
      else
        PaymentTable(
          payments: visible,
          now: now,
          overdueHours: PaymentConfig.reviewOverdueHours,
          onOpen: _open,
        ),
    ];
  }
}

/// Aviso de pendientes de revisión que el servidor no entregó.
class ReviewHiddenAlert extends StatelessWidget {
  const ReviewHiddenAlert({super.key, required this.count});

  /// `0` cuando se llegó al máximo pero no se sabe cuántos faltan.
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('review-hidden-alert'),
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
                Text(
                    count > 0
                        ? PaymentStrings.reviewHidden(count)
                        : PaymentStrings.reviewHiddenUnknown,
                    style: const TextStyle(
                        color: AppTheme.dangerText,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(PaymentStrings.reviewHiddenHelp,
                    style: TextStyle(color: AppTheme.dangerText)),
              ],
            ),
          ),
        ]),
      );
}
