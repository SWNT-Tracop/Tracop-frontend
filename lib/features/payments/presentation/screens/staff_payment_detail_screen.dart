import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../../home/presentation/home_screen.dart';
import '../../domain/entities/payment.dart';
import '../../domain/payment_permissions.dart';
import '../payment_error_text.dart';
import '../providers/payment_backoffice_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_detail_panel.dart';
import '../widgets/payment_dialogs.dart';
import '../widgets/payment_states.dart';
import '../widgets/ledger_section.dart';
import '../widgets/payment_settlements_section.dart';

/// Detalle del pago para el personal, con las acciones que permite su estado.
class StaffPaymentDetailScreen extends ConsumerStatefulWidget {
  const StaffPaymentDetailScreen(
      {super.key, required this.paymentId, this.fromSettlements = false});
  final String paymentId;

  /// Se abrió desde liquidaciones (`?desde=liquidaciones`).
  final bool fromSettlements;

  @override
  ConsumerState<StaffPaymentDetailScreen> createState() =>
      _StaffPaymentDetailScreenState();
}

class _StaffPaymentDetailScreenState
    extends ConsumerState<StaffPaymentDetailScreen> {
  Future<void> _reload() async {
    ref.invalidate(paymentDetailProvider(widget.paymentId));
    await ref
        .read(paymentDetailProvider(widget.paymentId).future)
        .then<void>((_) {}, onError: (_) {});
  }

  /// Muestra el diálogo y procesa su resultado (ver payment_dialogs.dart).
  Future<void> _runDialog(Widget dialog, String successMessage) async {
    final outcome = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
    if (!mounted || outcome == null) return;
    if (outcome is DomainFailure) {
      await VersionConflictDialog.show(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    }
    ref.invalidate(paymentReviewQueueProvider);
    // Verificar o resolver registra asientos y cambia las métricas.
    ref.invalidate(orderLedgerProvider);
    ref.invalidate(paymentsMetricsProvider);
    await _reload();
  }

  Widget _actions(Payment payment, String? role) {
    final repository = ref.read(paymentRepositoryProvider);
    final actions = PaymentPermissions.actionsFor(payment.status, role);
    if (actions.isEmpty) {
      return Text(PaymentStrings.noActions,
          style: Theme.of(context).textTheme.bodyMedium);
    }
    return Wrap(spacing: 12, runSpacing: 12, children: [
      if (actions.contains(PaymentAction.verify))
        FilledButton.icon(
          onPressed: () => _runDialog(
            VerifyPaymentDialog(
              payment: payment,
              onSubmit: () => repository.verify(payment.id, payment.version),
            ),
            PaymentStrings.verified,
          ),
          icon: const Icon(Icons.verified_outlined),
          label: const Text(PaymentStrings.verify),
        ),
      if (actions.contains(PaymentAction.reject))
        OutlinedButton.icon(
          onPressed: () => _runDialog(
            RejectPaymentDialog(
              onSubmit: (reason) =>
                  repository.reject(payment.id, payment.version, reason),
            ),
            PaymentStrings.rejected,
          ),
          icon: const Icon(Icons.block),
          label: const Text(PaymentStrings.reject),
        ),
      if (actions.contains(PaymentAction.resolveDispute))
        FilledButton.icon(
          onPressed: () => _runDialog(
            DisputeResolutionDialog(
              payment: payment,
              onSubmit: (outcome, note) => repository.resolveDispute(
                  payment.id, payment.version, outcome, note),
            ),
            PaymentStrings.resolved,
          ),
          icon: const Icon(Icons.gavel_outlined),
          label: const Text(PaymentStrings.resolve),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(paymentDetailProvider(widget.paymentId));
    final role = ref.watch(homeUserProvider).valueOrNull?.role;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(widget.fromSettlements
                    ? '/pagos/liquidaciones'
                    : '/pagos/revision'),
            icon: const Icon(Icons.arrow_back),
            label: Text(widget.fromSettlements
                ? SettlementStrings.backToSettlements
                : PaymentStrings.backToInbox),
          ),
        ),
        Text(PaymentStrings.detailTitle,
            style: textTheme.headlineMedium?.copyWith(fontSize: 20)),
        const SizedBox(height: 16),
        async.when(
          skipLoadingOnReload: true,
          loading: () => const PaymentLoadingSkeleton(rows: 5),
          error: (error, _) => PaymentErrorState(
            title: PaymentStrings.detailLoadError,
            message: error is DomainFailure
                ? paymentErrorText(error)
                : PaymentStrings.detailLoadError,
            onRetry: _reload,
          ),
          data: (payment) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentDetailPanel(
                payment: payment,
                onReloadProof: _reload,
                actions: _actions(payment, role),
              ),
              // Las liquidaciones se emiten al confirmar la entrega (`held`).
              if (payment.status == PaymentStatus.held ||
                  payment.status == PaymentStatus.settled) ...[
                const SizedBox(height: 32),
                PaymentSettlementsSection(
                    paymentId: payment.id, status: payment.status),
              ],
              const SizedBox(height: 32),
              LedgerSection(orderId: payment.orderId),
            ],
          ),
        ),
      ],
    );
  }
}
