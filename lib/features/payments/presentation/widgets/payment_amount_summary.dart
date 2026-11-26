import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';

/// Desglose de montos en COP (enteros). Para el comprador oculta la comisión
/// y el neto del proveedor salvo que se pida `staffView`.
class PaymentAmountSummary extends StatelessWidget {
  const PaymentAmountSummary({
    super.key,
    required this.subtotal,
    required this.freight,
    required this.total,
    this.commission,
    this.providerNet,
    this.caption,
  });

  final int subtotal;
  final int freight;
  final int total;
  final int? commission;
  final int? providerNet;
  final String? caption;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(PaymentStrings.subtotal, subtotal),
          _row(PaymentStrings.freight, freight),
          if (commission != null) _row(PaymentStrings.commission, commission!),
          const Divider(height: 24),
          _row(PaymentStrings.total, total, strong: true),
          if (providerNet != null)
            _row(PaymentStrings.providerNet, providerNet!),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(caption!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText)),
            ),
        ],
      );

  Widget _row(String label, int value, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: strong ? FontWeight.w700 : null)),
          ),
          Text(
            AppFormats.cop(value),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              fontSize: strong ? 18 : null,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: strong ? AppTheme.forest : AppTheme.ink,
            ),
          ),
        ]),
      );
}
