import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/payment_permissions.dart';
import '../payment_error_text.dart';

// Los diálogos envían la acción ellos mismos para poder deshabilitar el botón
// mientras la solicitud está en curso (sin doble envío). Al cerrar devuelven:
// - `Payment` si la acción se aplicó;
// - `DomainFailure` con `version_conflict`, para que la pantalla recargue;
// - `null` si se canceló.
// Otros errores se muestran dentro del diálogo y permiten reintentar.

const maxReasonLength = 500;

String? validateReason(String value) {
  final text = value.trim();
  if (text.isEmpty) return PaymentStrings.reasonRequired;
  if (text.length > maxReasonLength) return PaymentStrings.reasonTooLong;
  return null;
}

/// Estado común de los diálogos que envían: `busy`, error y `PopScope`.
mixin PaymentSubmitState<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  Widget buildDialog(BuildContext context);

  // Mientras la solicitud está en curso, "atrás" no cierra el diálogo.
  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: !busy, child: buildDialog(context));

  /// Envía la acción una sola vez. Genérico para reutilizarlo con otras
  /// entidades del módulo (p. ej. liquidaciones); `errorText` permite un
  /// traductor de errores propio.
  Future<void> submit<R extends Object>(
    Future<Result<R, DomainFailure>> Function() action, {
    String Function(DomainFailure failure) errorText = paymentErrorText,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await action();
    if (!mounted) return;
    switch (result) {
      case Ok(value: final value):
        Navigator.of(context).pop(value);
      case Err(error: final failure) when isPaymentVersionConflict(failure):
        Navigator.of(context).pop(failure);
      case Err(error: final failure):
        setState(() {
          busy = false;
          error = errorText(failure);
        });
    }
  }

  Widget errorMessage() => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(error!,
              style: const TextStyle(color: AppTheme.dangerStrong)),
        );

  Widget submitLabel(String label) => busy
      ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(label);
}

/// Aviso destacado dentro de un diálogo (advertencia o peligro).
class PaymentNotice extends StatelessWidget {
  const PaymentNotice(this.text, {super.key, this.danger = false});
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: danger ? AppTheme.dangerSurface : AppTheme.warningSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline,
              size: 20,
              color: danger ? AppTheme.dangerText : AppTheme.warningIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color:
                        danger ? AppTheme.dangerText : AppTheme.warningText)),
          ),
        ]),
      );
}

class VerifyPaymentDialog extends StatefulWidget {
  const VerifyPaymentDialog(
      {super.key, required this.payment, required this.onSubmit});
  final Payment payment;
  final Future<Result<Payment, DomainFailure>> Function() onSubmit;

  @override
  State<VerifyPaymentDialog> createState() => _VerifyPaymentDialogState();
}

class _VerifyPaymentDialogState extends State<VerifyPaymentDialog>
    with PaymentSubmitState {
  @override
  Widget buildDialog(BuildContext context) => AlertDialog(
        title: const Text(PaymentStrings.verifyTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(PaymentStrings.verifyBody),
              const SizedBox(height: 4),
              Text(AppFormats.cop(widget.payment.total),
                  style: const TextStyle(
                      color: AppTheme.forest,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(height: 12),
              const PaymentNotice(PaymentStrings.verifyConsequences),
              errorMessage(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text(CommonStrings.cancel),
          ),
          FilledButton(
            key: const Key('confirm-verify'),
            onPressed: busy ? null : () => submit(widget.onSubmit),
            child: submitLabel(PaymentStrings.confirmVerify),
          ),
        ],
      );
}

class RejectPaymentDialog extends StatefulWidget {
  const RejectPaymentDialog({super.key, required this.onSubmit});
  final Future<Result<Payment, DomainFailure>> Function(String reason) onSubmit;

  @override
  State<RejectPaymentDialog> createState() => _RejectPaymentDialogState();
}

class _RejectPaymentDialogState extends State<RejectPaymentDialog>
    with PaymentSubmitState {
  final _reason = TextEditingController();
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _send() {
    final validation = validateReason(_reason.text);
    setState(() => _reasonError = validation);
    if (validation != null) return;
    submit(() => widget.onSubmit(_reason.text.trim()));
  }

  @override
  Widget buildDialog(BuildContext context) => AlertDialog(
        title: const Text(PaymentStrings.rejectTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(PaymentStrings.rejectIntro),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final reason in PaymentStrings.rejectReasons)
                  ChoiceChip(
                    label: Text(reason),
                    selected: _reason.text.trim() == reason,
                    onSelected: busy
                        ? null
                        : (_) => setState(() {
                              _reason.text = reason;
                              _reasonError = null;
                            }),
                  ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                enabled: !busy,
                maxLength: maxReasonLength,
                maxLines: 3,
                minLines: 2,
                onChanged: (_) => setState(() => _reasonError = null),
                decoration: InputDecoration(
                  labelText: PaymentStrings.rejectReasonLabel,
                  errorText: _reasonError,
                ),
              ),
              const PaymentNotice(PaymentStrings.rejectConsequences),
              errorMessage(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text(CommonStrings.cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.dangerStrong),
            onPressed: busy ? null : _send,
            child: submitLabel(PaymentStrings.confirmReject),
          ),
        ],
      );
}

class DisputeResolutionDialog extends StatefulWidget {
  const DisputeResolutionDialog(
      {super.key, required this.payment, required this.onSubmit});
  final Payment payment;
  final Future<Result<Payment, DomainFailure>> Function(
      DisputeOutcome outcome, String note) onSubmit;

  @override
  State<DisputeResolutionDialog> createState() =>
      _DisputeResolutionDialogState();
}

class _DisputeResolutionDialogState extends State<DisputeResolutionDialog>
    with PaymentSubmitState {
  final _note = TextEditingController();
  DisputeOutcome? _outcome;
  String? _noteError;
  String? _outcomeError;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _send() {
    final noteError = validateReason(_note.text);
    setState(() {
      _noteError = noteError;
      _outcomeError = _outcome == null ? PaymentStrings.chooseOutcome : null;
    });
    if (noteError != null || _outcome == null) return;
    final outcome = _outcome!;
    submit(() => widget.onSubmit(outcome, _note.text.trim()));
  }

  Widget _option({
    required DisputeOutcome value,
    required IconData icon,
    required String title,
    required String body,
    required bool enabled,
  }) {
    final selected = _outcome == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppTheme.mint : AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          side: BorderSide(
              color: selected ? AppTheme.primary : AppTheme.outline,
              width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          onTap: enabled && !busy
              ? () => setState(() {
                    _outcome = value;
                    _outcomeError = null;
                  })
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: enabled ? AppTheme.forest : AppTheme.mutedText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                enabled ? AppTheme.ink : AppTheme.mutedText)),
                    const SizedBox(height: 2),
                    Text(enabled ? body : PaymentStrings.releaseUnavailable,
                        style: const TextStyle(color: AppTheme.mutedText)),
                  ],
                ),
              ),
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppTheme.forest : AppTheme.mutedText),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context) {
    final canRelease = PaymentPermissions.canRelease(widget.payment);
    return AlertDialog(
      title: const Text(PaymentStrings.resolveTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.payment.disputeReason != null) ...[
              const Text(PaymentStrings.disputeReason,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(widget.payment.disputeReason!),
              const SizedBox(height: 12),
            ],
            _option(
              value: DisputeOutcome.release,
              icon: Icons.storefront_outlined,
              title: PaymentStrings.releaseTitle,
              body: PaymentStrings.releaseBody,
              enabled: canRelease,
            ),
            _option(
              value: DisputeOutcome.refund,
              icon: Icons.undo,
              title: PaymentStrings.refundTitle,
              body: PaymentStrings.refundBody,
              enabled: true,
            ),
            if (_outcomeError != null)
              Text(_outcomeError!,
                  style: const TextStyle(color: AppTheme.dangerStrong)),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              enabled: !busy,
              maxLength: maxReasonLength,
              maxLines: 3,
              minLines: 2,
              onChanged: (_) => setState(() => _noteError = null),
              decoration: InputDecoration(
                labelText: PaymentStrings.resolutionNoteLabel,
                hintText: PaymentStrings.resolutionNoteHint,
                errorText: _noteError,
              ),
            ),
            const PaymentNotice(PaymentStrings.orderWillClose),
            errorMessage(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text(CommonStrings.cancel),
        ),
        FilledButton(
          onPressed: busy ? null : _send,
          child: submitLabel(_outcome == DisputeOutcome.refund
              ? PaymentStrings.confirmRefund
              : _outcome == DisputeOutcome.release
                  ? PaymentStrings.confirmRelease
                  : PaymentStrings.resolve),
        ),
      ],
    );
  }
}

/// Formulario de disputa del comprador con paso de confirmación.
class OpenDisputeDialog extends StatefulWidget {
  const OpenDisputeDialog({super.key, required this.onSubmit});
  final Future<Result<Payment, DomainFailure>> Function(String reason) onSubmit;

  @override
  State<OpenDisputeDialog> createState() => _OpenDisputeDialogState();
}

class _OpenDisputeDialogState extends State<OpenDisputeDialog>
    with PaymentSubmitState {
  final _reason = TextEditingController();
  String? _reasonError;
  bool _confirming = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _next() {
    final validation = validateReason(_reason.text);
    setState(() {
      _reasonError = validation;
      _confirming = validation == null;
    });
  }

  @override
  Widget buildDialog(BuildContext context) => AlertDialog(
        title: Text(_confirming
            ? PaymentStrings.confirmDisputeTitle
            : PaymentStrings.disputeTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _confirming
                ? [
                    const Text(PaymentStrings.confirmDisputeBody),
                    const SizedBox(height: 12),
                    Text('"${_reason.text.trim()}"',
                        style: const TextStyle(color: AppTheme.ink)),
                    errorMessage(),
                  ]
                : [
                    const Text(PaymentStrings.disputeIntro),
                    const SizedBox(height: 12),
                    const PaymentNotice(PaymentStrings.disputeWarning,
                        danger: true),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reason,
                      maxLength: maxReasonLength,
                      maxLines: 4,
                      minLines: 2,
                      onChanged: (_) => setState(() => _reasonError = null),
                      decoration: InputDecoration(
                        labelText: PaymentStrings.disputeReasonLabel,
                        hintText: PaymentStrings.disputeReasonHint,
                        errorText: _reasonError,
                      ),
                    ),
                  ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy
                ? null
                : () => _confirming
                    ? setState(() => _confirming = false)
                    : Navigator.pop(context),
            child:
                Text(_confirming ? CommonStrings.back : CommonStrings.cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.dangerStrong),
            onPressed: busy
                ? null
                : _confirming
                    ? () => submit(() => widget.onSubmit(_reason.text.trim()))
                    : _next,
            child: submitLabel(_confirming
                ? PaymentStrings.confirmDispute
                : PaymentStrings.openDispute),
          ),
        ],
      );
}

class VersionConflictDialog extends StatelessWidget {
  const VersionConflictDialog({
    super.key,
    this.title = PaymentStrings.conflictTitle,
    this.body = PaymentStrings.conflictBody,
  });

  final String title;
  final String body;

  static Future<void> show(
    BuildContext context, {
    String title = PaymentStrings.conflictTitle,
    String body = PaymentStrings.conflictBody,
  }) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => VersionConflictDialog(title: title, body: body),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: const Icon(Icons.sync_problem, color: AppTheme.warningIcon),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh),
            label: const Text(PaymentStrings.loadLatest),
          ),
        ],
      );
}
