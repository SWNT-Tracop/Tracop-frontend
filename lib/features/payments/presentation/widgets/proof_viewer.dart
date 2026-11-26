import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/strings.dart';
import 'payment_states.dart';

/// Muestra el comprobante desde la URL firmada. La URL no se guarda, no se
/// registra y no se muestra como texto. Si la imagen falla (403 o vencida),
/// ofrece volver a pedir el pago para obtener una URL nueva.
class ProofViewer extends StatefulWidget {
  const ProofViewer({super.key, required this.url, required this.onReload});

  final String? url;
  final Future<void> Function() onReload;

  @override
  State<ProofViewer> createState() => _ProofViewerState();
}

class _ProofViewerState extends State<ProofViewer> {
  String? _failedUrl;
  bool _reloading = false;

  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      await widget.onReload();
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  void _openLarge(BuildContext context, String url) => showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: PaymentStrings.proofImageLabel,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(PaymentStrings.expiredLinkTitle),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(PaymentStrings.close),
                ),
              ),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null) {
      return Text(PaymentStrings.proofUnavailable,
          style: Theme.of(context).textTheme.bodyMedium);
    }
    if (_failedUrl == url) {
      return ExpiredSignedUrlState(onReload: _reload, reloading: _reloading);
    }
    return Semantics(
      button: true,
      label: PaymentStrings.openProof,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        onTap: () => _openLarge(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: Image.network(
              url,
              key: ValueKey(url),
              fit: BoxFit.contain,
              semanticLabel: PaymentStrings.proofImageLabel,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator())),
              errorBuilder: (context, error, stackTrace) {
                // Se marca después del frame para no llamar setState en build.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _failedUrl != url) {
                    setState(() => _failedUrl = url);
                  }
                });
                return const SizedBox(height: 160);
              },
            ),
          ),
        ),
      ),
    );
  }
}
