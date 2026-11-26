import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';
import 'payment_amount_summary.dart';
import 'payment_badges.dart';
import 'payment_timeline.dart';
import 'proof_viewer.dart';

/// Detalle completo de un pago para el personal de TRACOP.
class PaymentDetailPanel extends StatelessWidget {
  const PaymentDetailPanel({
    super.key,
    required this.payment,
    required this.onReloadProof,
    this.actions,
  });

  final Payment payment;
  final Future<void> Function() onReloadProof;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final section = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 12, runSpacing: 8, children: [
          PaymentStatusBadge.of(payment, large: true),
          PaymentMethodBadge(method: payment.method, wire: payment.methodCode),
        ]),
        const SizedBox(height: 16),
        _CopyableId(label: PaymentStrings.paymentId, value: payment.id),
        _CopyableId(label: PaymentStrings.orderId, value: payment.orderId),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(PaymentStrings.orderAccessNote,
              style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText)),
        ),
        _Field(PaymentStrings.version, '${payment.version}'),
        _Field(PaymentStrings.createdAt,
            AppFormats.bogotaDateTime(payment.createdAt)),
        if (payment.proofUploadedAt != null)
          _Field(PaymentStrings.proofUploadedAt,
              AppFormats.bogotaDateTime(payment.proofUploadedAt!)),
        if (payment.reviewedAt != null)
          _Field(PaymentStrings.reviewedAt,
              AppFormats.bogotaDateTime(payment.reviewedAt!)),
        if (payment.heldAt != null)
          _Field(PaymentStrings.heldAt,
              AppFormats.bogotaDateTime(payment.heldAt!)),
        _Field(PaymentStrings.updatedAt,
            AppFormats.bogotaDateTime(payment.updatedAt)),
        if (payment.rejectionReason != null)
          _Reason(PaymentStrings.rejectionReason, payment.rejectionReason!),
        if (payment.disputeReason != null)
          _Reason(PaymentStrings.disputeReason, payment.disputeReason!),
        const SizedBox(height: 16),
        PaymentAmountSummary(
          subtotal: payment.subtotal,
          freight: payment.freight,
          commission: payment.commission,
          total: payment.total,
          providerNet: payment.providerNet,
        ),
        if (actions != null) ...[const SizedBox(height: 20), actions!],
      ],
    );

    final evidence = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PaymentStrings.proofTitle, style: section),
        const SizedBox(height: 8),
        ProofViewer(url: payment.proofUrl, onReload: onReloadProof),
        const SizedBox(height: 24),
        PaymentTimeline(payment: payment),
      ],
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [summary, const SizedBox(height: 24), evidence],
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: summary),
      const SizedBox(width: 32),
      Expanded(child: evidence),
    ]);
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 150,
            child:
                Text(label, style: const TextStyle(color: AppTheme.mutedText)),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(color: AppTheme.ink))),
        ]),
      );
}

class _Reason extends StatelessWidget {
  const _Reason(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.neutralSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.ink)),
        ]),
      );
}

class _CopyableId extends StatelessWidget {
  const _CopyableId({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
          width: 150,
          child: Text(label, style: const TextStyle(color: AppTheme.mutedText)),
        ),
        Expanded(
          child: SelectableText(value,
              style: const TextStyle(
                  color: AppTheme.ink,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ),
        IconButton(
          tooltip: PaymentStrings.copyId,
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(PaymentStrings.idCopied)));
          },
        ),
      ]);
}
