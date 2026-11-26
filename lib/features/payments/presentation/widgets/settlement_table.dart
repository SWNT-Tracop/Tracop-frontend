import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/settlement.dart';
import 'settlement_badges.dart';

/// Liquidaciones: tabla en pantallas anchas y tarjetas en angostas, como la
/// bandeja de revisión.
class SettlementTable extends StatelessWidget {
  const SettlementTable({
    super.key,
    required this.settlements,
    required this.onOpenPayment,
    required this.onMarkPaid,
  });

  final List<Settlement> settlements;
  final ValueChanged<Settlement> onOpenPayment;
  final ValueChanged<Settlement> onMarkPaid;

  static const wideBreakpoint = 1000.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= wideBreakpoint
                ? _WideTable(table: this)
                : Column(children: [
                    for (final settlement in settlements)
                      _SettlementCard(table: this, settlement: settlement),
                  ]),
      );
}

const _mono = TextStyle(
    color: AppTheme.ink,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()]);

class _PaymentLink extends StatelessWidget {
  const _PaymentLink({required this.settlement, required this.onOpen});
  final Settlement settlement;
  final ValueChanged<Settlement> onOpen;

  @override
  Widget build(BuildContext context) {
    final short = PaymentStrings.shortId(settlement.paymentId);
    return Semantics(
      link: true,
      label: SettlementStrings.openPayment(short),
      child: InkWell(
        onTap: () => onOpen(settlement),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(short,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ),
      ),
    );
  }
}

class _MarkPaidButton extends StatelessWidget {
  const _MarkPaidButton({required this.settlement, required this.onMarkPaid});
  final Settlement settlement;
  final ValueChanged<Settlement> onMarkPaid;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        key: Key('mark-paid-${settlement.id}'),
        onPressed: () => onMarkPaid(settlement),
        icon: const Icon(Icons.payments_outlined, size: 18),
        label: const Text(SettlementStrings.markPaid),
      );
}

/// Sin referencia: "Sin referencia" si ya no está por pagar; guion si
/// todavía está emitida (aún no aplica).
String _reference(Settlement settlement) =>
    settlement.reference ??
    (settlement.canMarkPaid
        ? SettlementStrings.noDate
        : SettlementStrings.noReference);

String _date(DateTime? value) =>
    value == null ? SettlementStrings.noDate : AppFormats.bogotaDate(value);

class _WideTable extends StatelessWidget {
  const _WideTable({required this.table});
  final SettlementTable table;

  static const _flex = [3, 2, 2, 3, 3, 2, 2, 3, 3];

  Widget _cells(List<Widget> cells) => Row(children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: _flex[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Align(alignment: Alignment.centerLeft, child: cells[i]),
            ),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(
        color: AppTheme.mutedText, fontWeight: FontWeight.w600, fontSize: 13);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: _cells(const [
            Text(SettlementStrings.columnBeneficiary, style: header),
            Text(SettlementStrings.columnOrder, style: header),
            Text(SettlementStrings.columnPayment, style: header),
            Text(SettlementStrings.columnAmount, style: header),
            Text(SettlementStrings.columnStatus, style: header),
            Text(SettlementStrings.columnIssued, style: header),
            Text(SettlementStrings.columnPaid, style: header),
            Text(SettlementStrings.columnReference, style: header),
            SizedBox.shrink(),
          ]),
        ),
        const Divider(height: 1),
        for (final settlement in table.settlements) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: _cells([
              BeneficiaryLabel(settlement: settlement),
              Text(PaymentStrings.shortId(settlement.orderId), style: _mono),
              _PaymentLink(settlement: settlement, onOpen: table.onOpenPayment),
              Text(AppFormats.cop(settlement.amount), style: _mono),
              SettlementStatusBadge(
                  status: settlement.status, wire: settlement.statusCode),
              Text(_date(settlement.issuedAt)),
              Text(_date(settlement.paidAt)),
              Text(_reference(settlement),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (settlement.canMarkPaid)
                _MarkPaidButton(
                    settlement: settlement, onMarkPaid: table.onMarkPaid)
              else
                const SizedBox.shrink(),
            ]),
          ),
          if (settlement != table.settlements.last) const Divider(height: 1),
        ],
      ]),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.table, required this.settlement});
  final SettlementTable table;
  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: AppTheme.mutedText);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: BeneficiaryLabel(settlement: settlement)),
              Text(AppFormats.cop(settlement.amount),
                  style: const TextStyle(
                      color: AppTheme.forest,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SettlementStatusBadge(
                    status: settlement.status, wire: settlement.statusCode),
                Text(
                    '${SettlementStrings.columnOrder} ${PaymentStrings.shortId(settlement.orderId)}',
                    style: muted),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('${SettlementStrings.columnPayment} ',
                      style: muted),
                  _PaymentLink(
                      settlement: settlement, onOpen: table.onOpenPayment),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                SettlementStrings.issuedOn(
                    AppFormats.bogotaDateTime(settlement.issuedAt)),
                style: muted),
            if (settlement.paidAt != null)
              Text(
                  SettlementStrings.paidOn(
                      AppFormats.bogotaDateTime(settlement.paidAt!)),
                  style: muted),
            if (!settlement.canMarkPaid)
              Text(
                  '${SettlementStrings.columnReference}: '
                  '${settlement.reference ?? SettlementStrings.noReference}',
                  style: const TextStyle(color: AppTheme.ink)),
            if (settlement.canMarkPaid) ...[
              const SizedBox(height: 12),
              _MarkPaidButton(
                  settlement: settlement, onMarkPaid: table.onMarkPaid),
            ],
          ],
        ),
      ),
    );
  }
}
