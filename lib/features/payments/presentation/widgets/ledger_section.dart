import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/ledger.dart';
import '../payment_error_text.dart';
import '../providers/payment_backoffice_provider.dart';
import 'payment_states.dart';

/// Libro contable del pedido (`GET /orders/{id}/ledger`), solo lectura.
class LedgerSection extends ConsumerWidget {
  const LedgerSection({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderLedgerProvider(orderId));
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(LedgerStrings.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(LedgerStrings.readOnly,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText)),
        const SizedBox(height: 12),
        async.when(
          skipLoadingOnReload: true,
          loading: () => const PaymentLoadingSkeleton(rows: 2),
          error: (error, _) => PaymentErrorState(
            title: LedgerStrings.loadError,
            message: error is DomainFailure
                ? paymentErrorText(error)
                : LedgerStrings.loadError,
            onRetry: () => ref.invalidate(orderLedgerProvider(orderId)),
          ),
          data: (summary) => summary.isEmpty
              ? Text(LedgerStrings.empty, style: textTheme.bodyMedium)
              : LedgerView(summary: summary),
        ),
      ],
    );
  }
}

/// Transacciones agrupadas con su indicador de cuadre y el total.
class LedgerView extends StatelessWidget {
  const LedgerView({super.key, required this.summary});
  final LedgerSummary summary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final transaction in summary.transactions)
            _TransactionCard(transaction: transaction),
          _TotalRow(summary: summary),
        ],
      );
}

class BalanceChip extends StatelessWidget {
  const BalanceChip(
      {super.key,
      required this.balanced,
      required this.difference,
      this.unbalancedLabel});
  final bool balanced;
  final int difference;

  /// Texto cuando no cuadra; por defecto "Descuadre de $X".
  final String? unbalancedLabel;

  @override
  Widget build(BuildContext context) {
    final background = balanced ? AppTheme.mint : AppTheme.dangerSurface;
    final foreground = balanced ? AppTheme.forest : AppTheme.dangerText;
    final label = balanced
        ? LedgerStrings.balanced
        : unbalancedLabel ??
            LedgerStrings.unbalanced(AppFormats.cop(difference));
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(balanced ? Icons.check_circle_outline : Icons.warning_amber,
            size: 14, color: foreground),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label,
              style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
      ]),
    );
    return balanced
        ? chip
        : Tooltip(message: LedgerStrings.unbalancedHelp, child: chip);
  }
}

const _amountStyle = TextStyle(
    color: AppTheme.ink, fontFeatures: [FontFeature.tabularFigures()]);

String _amount(int value) =>
    value == 0 ? LedgerStrings.zero : AppFormats.cop(value);

// En pantallas angostas (o con texto grande) los montos se reducen para
// caber en su columna en vez de desbordarse; la cuenta puede ocupar varias
// líneas.
Widget _amountCell(Widget child) => Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: child),
    );

Widget _row(Widget account, Widget debit, Widget credit) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(flex: 5, child: account),
        const SizedBox(width: 4),
        Expanded(flex: 3, child: _amountCell(debit)),
        const SizedBox(width: 4),
        Expanded(flex: 3, child: _amountCell(credit)),
      ]),
    );

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});
  final LedgerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(
        color: AppTheme.mutedText, fontWeight: FontWeight.w600, fontSize: 12);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(LedgerStrings.kind(transaction.kindCode),
                    style: TextStyle(
                        color: transaction.kind == LedgerKind.unknown
                            ? AppTheme.mutedText
                            : AppTheme.ink,
                        fontWeight: FontWeight.w700)),
                Text(AppFormats.bogotaDateTime(transaction.createdAt),
                    style: const TextStyle(color: AppTheme.mutedText)),
                BalanceChip(
                  balanced: transaction.isBalanced,
                  difference:
                      (transaction.totalDebit - transaction.totalCredit).abs(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(
              const Text(LedgerStrings.account, style: header),
              const Text(LedgerStrings.debit, style: header),
              const Text(LedgerStrings.credit, style: header),
            ),
            for (final entry in transaction.entries)
              _row(
                Text(LedgerStrings.accountName(entry.account),
                    style: const TextStyle(color: AppTheme.ink)),
                Text(_amount(entry.debit), style: _amountStyle),
                Text(_amount(entry.credit), style: _amountStyle),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.summary});
  final LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(
        color: AppTheme.ink,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()]);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutralSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            const Text(LedgerStrings.total, style: bold),
            Text(AppFormats.cop(summary.totalDebit), style: bold),
            Text(AppFormats.cop(summary.totalCredit), style: bold),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: BalanceChip(
              balanced: summary.isBalanced,
              difference: summary.difference,
              // El total puede cuadrar aunque una transacción no lo haga:
              // en ese caso "Descuadre de $0" sería engañoso.
              unbalancedLabel:
                  summary.difference == 0 ? LedgerStrings.someUnbalanced : null,
            ),
          ),
          if (!summary.isBalanced)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(LedgerStrings.unbalancedHelp,
                  style: TextStyle(color: AppTheme.dangerText)),
            ),
        ],
      ),
    );
  }
}
