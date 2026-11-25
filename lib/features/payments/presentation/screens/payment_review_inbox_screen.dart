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

  void _refresh() => ref.invalidate(paymentReviewQueueProvider);

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
    return [
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
