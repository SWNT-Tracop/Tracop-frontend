import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';
import '../../domain/review_filters.dart';
import 'payment_badges.dart';

/// Lista de pagos para revisión: tabla en pantallas anchas, tarjetas en
/// pantallas angostas.
class PaymentTable extends StatelessWidget {
  const PaymentTable({
    super.key,
    required this.payments,
    required this.now,
    required this.overdueHours,
    required this.onOpen,
  });

  final List<Payment> payments;
  final DateTime now;
  final int overdueHours;
  final ValueChanged<Payment> onOpen;

  static const wideBreakpoint = 840.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= wideBreakpoint
                ? _WideTable(table: this)
                : Column(children: [
                    for (final payment in payments)
                      _PaymentCard(table: this, payment: payment),
                  ]),
      );
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.payment, required this.table});
  final Payment payment;
  final PaymentTable table;

  @override
  Widget build(BuildContext context) {
    final overdue =
        isReviewOverdue(payment, table.now, hours: table.overdueHours);
    final age = table.now.difference(payment.waitingSince);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (overdue) ...[
        Tooltip(
          message: PaymentStrings.overdueTooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.dangerSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppTheme.dangerText),
              const SizedBox(width: 4),
              Text(PaymentStrings.overdue(table.overdueHours),
                  style: const TextStyle(
                      color: AppTheme.dangerText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
      ],
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(PaymentStrings.waiting(age.isNegative ? Duration.zero : age),
                style: const TextStyle(color: AppTheme.mutedText)),
            // Fecha absoluta (hora de Bogotá) de la misma marca que usa
            // "en espera": comprobante enviado o última actualización.
            Text(
              PaymentStrings.waitingSinceAt(
                  AppFormats.bogotaDateTime(payment.waitingSince)),
              key: Key('waiting-since-${payment.id}'),
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _WideTable extends StatelessWidget {
  const _WideTable({required this.table});
  final PaymentTable table;

  static const _flex = [2, 2, 2, 4, 2, 3];

  Widget _cells(List<Widget> cells) => Row(children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: _flex[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(alignment: Alignment.centerLeft, child: cells[i]),
            ),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(
        color: AppTheme.mutedText, fontWeight: FontWeight.w600, fontSize: 13);
    const mono = TextStyle(
        color: AppTheme.ink,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()]);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: _cells(const [
            Text(PaymentStrings.columnPayment, style: header),
            Text(PaymentStrings.columnOrder, style: header),
            Text(PaymentStrings.columnMethod, style: header),
            Text(PaymentStrings.columnStatus, style: header),
            Text(PaymentStrings.columnTotal, style: header),
            Text(PaymentStrings.columnWaiting, style: header),
          ]),
        ),
        const Divider(height: 1),
        for (final payment in table.payments) ...[
          InkWell(
            onTap: () => table.onOpen(payment),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: _cells([
                Text(PaymentStrings.shortId(payment.id), style: mono),
                Text(PaymentStrings.shortId(payment.orderId), style: mono),
                PaymentMethodBadge(
                    method: payment.method, wire: payment.methodCode),
                PaymentStatusBadge.of(payment),
                Text(AppFormats.cop(payment.total), style: mono),
                _Waiting(payment: payment, table: table),
              ]),
            ),
          ),
          if (payment != table.payments.last) const Divider(height: 1),
        ],
      ]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.table, required this.payment});
  final PaymentTable table;
  final Payment payment;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSurface),
          onTap: () => table.onOpen(payment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      '${PaymentStrings.columnPayment} ${PaymentStrings.shortId(payment.id)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(AppFormats.cop(payment.total),
                      style: const TextStyle(
                          color: AppTheme.forest,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ]),
                const SizedBox(height: 4),
                Text(
                    '${PaymentStrings.columnOrder} ${PaymentStrings.shortId(payment.orderId)}',
                    style: const TextStyle(color: AppTheme.mutedText)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PaymentStatusBadge.of(payment),
                    PaymentMethodBadge(
                        method: payment.method, wire: payment.methodCode),
                  ],
                ),
                const SizedBox(height: 8),
                _Waiting(payment: payment, table: table),
              ],
            ),
          ),
        ),
      );
}
