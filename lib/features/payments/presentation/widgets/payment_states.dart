import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/strings.dart';

// El repo no tiene estados vacíos/carga/error compartidos (cada pantalla
// define los suyos como privados); estos son los del módulo de pagos.

class PaymentEmptyState extends StatelessWidget {
  const PaymentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(children: [
          Icon(icon, size: 42, color: AppTheme.mutedText),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      );
}

/// Bloques grises con la forma del contenido; sin animación.
class PaymentLoadingSkeleton extends StatelessWidget {
  const PaymentLoadingSkeleton({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
        label: PaymentStrings.loading,
        child: Column(children: [
          for (var i = 0; i < rows; i++)
            Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.neutralSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              ),
            ),
        ]),
      );
}

class PaymentErrorState extends StatelessWidget {
  const PaymentErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.dangerSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.dangerText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppTheme.dangerText,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: AppTheme.dangerText)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(CommonStrings.retry),
            ),
          ],
        ),
      );
}

/// La URL firmada del comprobante venció o fue rechazada (403).
class ExpiredSignedUrlState extends StatelessWidget {
  const ExpiredSignedUrlState(
      {super.key, required this.onReload, this.reloading = false});
  final VoidCallback onReload;
  final bool reloading;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Column(
          children: [
            const Icon(Icons.link_off, color: AppTheme.mutedText, size: 32),
            const SizedBox(height: 8),
            Text(PaymentStrings.expiredLinkTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(PaymentStrings.expiredLinkBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: reloading ? null : onReload,
              icon: const Icon(Icons.refresh),
              label: const Text(PaymentStrings.reload),
            ),
          ],
        ),
      );
}
