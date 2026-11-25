import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/settlement.dart';

class SettlementStatusBadge extends StatelessWidget {
  const SettlementStatusBadge({super.key, required this.status, this.wire});
  final SettlementStatus status;

  /// Código recibido del API; se usa para rotular estados desconocidos.
  final String? wire;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      SettlementStatus.paid => (AppTheme.mint, AppTheme.forest, Icons.task_alt),
      SettlementStatus.issued => (
          AppTheme.warningSurface,
          AppTheme.warningText,
          Icons.schedule
        ),
      SettlementStatus.unknown => (
          AppTheme.neutralSurface,
          AppTheme.mutedText,
          Icons.help_outline
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            SettlementStrings.status(wire ?? status.wire),
            style: TextStyle(
                color: foreground, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

/// Tipo de beneficiario con su id corto (el API no trae el nombre).
class BeneficiaryLabel extends StatelessWidget {
  const BeneficiaryLabel({super.key, required this.settlement});
  final Settlement settlement;

  static IconData iconFor(BeneficiaryKind kind) => switch (kind) {
        BeneficiaryKind.producer => Icons.storefront_outlined,
        BeneficiaryKind.carrier => Icons.local_shipping_outlined,
        BeneficiaryKind.unknown => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(settlement.beneficiaryKind),
              size: 18, color: AppTheme.mutedText),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SettlementStrings.kind(settlement.beneficiaryKindCode),
                    style: TextStyle(
                        color: settlement.beneficiaryKind ==
                                BeneficiaryKind.unknown
                            ? AppTheme.mutedText
                            : AppTheme.ink,
                        fontWeight: FontWeight.w600)),
                Text(PaymentStrings.shortId(settlement.beneficiaryId),
                    style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ],
      );
}
