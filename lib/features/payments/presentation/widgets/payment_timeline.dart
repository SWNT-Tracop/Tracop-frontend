import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';

/// "Hitos del pago": solo las marcas de tiempo que el API registra. No hay
/// endpoint de historial, así que no se inventan eventos intermedios.
class PaymentTimeline extends StatelessWidget {
  const PaymentTimeline({super.key, required this.payment});
  final Payment payment;

  String _label(PaymentMilestoneKind kind) => switch (kind) {
        PaymentMilestoneKind.created => PaymentStrings.milestoneCreated,
        PaymentMilestoneKind.proofUploaded =>
          PaymentStrings.milestoneProofUploaded,
        PaymentMilestoneKind.verified => PaymentStrings.milestoneVerified,
        PaymentMilestoneKind.rejected => PaymentStrings.milestoneRejected,
        PaymentMilestoneKind.held => PaymentStrings.milestoneHeld,
        PaymentMilestoneKind.disputed => PaymentStrings.milestoneDisputed,
        PaymentMilestoneKind.disputeResolved =>
          PaymentStrings.milestoneDisputeResolved,
        PaymentMilestoneKind.current => PaymentStrings.milestoneCurrent(
            PaymentStrings.statusLabel(payment.statusCode,
                disputeResolved: payment.disputeResolved)),
      };

  @override
  Widget build(BuildContext context) {
    final items = paymentMilestones(payment);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(PaymentStrings.milestonesTitle,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
            '${PaymentStrings.milestonesHint} ${PaymentStrings.bogotaTimeNote}',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText)),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: items[i].kind == PaymentMilestoneKind.current
                            ? AppTheme.primary
                            : AppTheme.white,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                    ),
                    if (i < items.length - 1)
                      const Expanded(
                        child: VerticalDivider(
                            width: 2, thickness: 2, color: AppTheme.outline),
                      ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_label(items[i].kind),
                            style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w600)),
                        Text(
                          items[i].at == null
                              ? PaymentStrings.milestoneNoDate
                              : AppFormats.bogotaDateTime(items[i].at!),
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
