import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.wire,
    this.large = false,
    this.disputeResolved = false,
  });

  /// Insignia de un pago: rotula "Disputa resuelta" si se liberó.
  PaymentStatusBadge.of(Payment payment, {Key? key, bool large = false})
      : this(
          key: key,
          status: payment.status,
          wire: payment.statusCode,
          large: large,
          disputeResolved: payment.disputeResolved,
        );

  final PaymentStatus status;

  /// Código recibido del API; se usa para rotular estados desconocidos.
  final String? wire;
  final bool large;

  /// Pago `held` con disputa liberada (solo cambia el rótulo y el ícono).
  final bool disputeResolved;

  /// Estilo para mostrar un pago concreto (considera la disputa resuelta).
  static ({Color background, Color foreground, IconData icon}) styleForPayment(
      Payment payment) {
    final style = styleFor(payment.status);
    return payment.disputeResolved
        ? (
            background: style.background,
            foreground: style.foreground,
            icon: Icons.gavel_outlined,
          )
        : style;
  }

  static ({Color background, Color foreground, IconData icon}) styleFor(
          PaymentStatus status) =>
      switch (status) {
        PaymentStatus.pending => (
            background: AppTheme.warningSurface,
            foreground: AppTheme.warningText,
            icon: Icons.schedule,
          ),
        PaymentStatus.proofUploaded => (
            background: AppTheme.infoSurface,
            foreground: AppTheme.infoText,
            icon: Icons.fact_check_outlined,
          ),
        PaymentStatus.verified || PaymentStatus.settled => (
            background: AppTheme.mint,
            foreground: AppTheme.forest,
            icon: Icons.verified_outlined,
          ),
        PaymentStatus.held => (
            background: AppTheme.mint,
            foreground: AppTheme.forest,
            icon: Icons.lock_clock_outlined,
          ),
        PaymentStatus.rejected => (
            background: AppTheme.dangerSurface,
            foreground: AppTheme.dangerText,
            icon: Icons.block,
          ),
        PaymentStatus.disputed => (
            background: AppTheme.dangerSurface,
            foreground: AppTheme.dangerText,
            icon: Icons.report_gmailerrorred_outlined,
          ),
        PaymentStatus.refunded => (
            background: AppTheme.neutralSurface,
            foreground: AppTheme.ink,
            icon: Icons.undo,
          ),
        PaymentStatus.unknown => (
            background: AppTheme.neutralSurface,
            foreground: AppTheme.mutedText,
            icon: Icons.help_outline,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final style = styleFor(status);
    final icon = disputeResolved ? Icons.gavel_outlined : style.icon;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: large ? 18 : 14, color: style.foreground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            PaymentStrings.statusLabel(wire ?? status.wire,
                disputeResolved: disputeResolved),
            style: TextStyle(
              color: style.foreground,
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12,
            ),
          ),
        ),
      ]),
    );
  }
}

class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.method, this.wire});
  final PaymentMethod method;

  /// Código recibido del API; se usa para rotular medios desconocidos.
  final String? wire;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (method) {
              PaymentMethod.nequi => Icons.phone_iphone,
              PaymentMethod.transfer => Icons.account_balance_outlined,
              PaymentMethod.unknown => Icons.help_outline,
            },
            size: 16,
            color: AppTheme.mutedText,
          ),
          const SizedBox(width: 6),
          Text(PaymentStrings.method(wire ?? method.wire),
              style: const TextStyle(
                  color: AppTheme.ink, fontWeight: FontWeight.w500)),
        ],
      );
}
