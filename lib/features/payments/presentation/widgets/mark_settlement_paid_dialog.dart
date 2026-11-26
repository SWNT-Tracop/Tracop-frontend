import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/settlement.dart';
import '../payment_error_text.dart';
import 'payment_dialogs.dart';

String? validateSettlementReference(String value) {
  final text = value.trim();
  if (text.isEmpty) return SettlementStrings.referenceRequired;
  if (text.length > maxSettlementReferenceLength) {
    return SettlementStrings.referenceTooLong;
  }
  return null;
}

/// Registra el pago de una liquidación en dos pasos (datos → confirmación).
///
/// La referencia es opcional en el API pero obligatoria aquí: el API no
/// expone quién marcó el pago, así que la referencia es la única pista
/// visible para conciliar con el banco (ver payments-decisions.md).
///
/// Al cerrar devuelve `Settlement` (pagada), `DomainFailure` con
/// `version_conflict` (recargar) o `null` (cancelado).
class MarkSettlementPaidDialog extends StatefulWidget {
  const MarkSettlementPaidDialog({
    super.key,
    required this.settlement,
    required this.onSubmit,
  });

  final Settlement settlement;
  final Future<Result<Settlement, DomainFailure>> Function(String reference)
      onSubmit;

  @override
  State<MarkSettlementPaidDialog> createState() =>
      _MarkSettlementPaidDialogState();
}

class _MarkSettlementPaidDialogState extends State<MarkSettlementPaidDialog>
    with PaymentSubmitState {
  final _reference = TextEditingController();
  String? _referenceError;
  bool _confirming = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  void _next() {
    final validation = validateSettlementReference(_reference.text);
    setState(() {
      _referenceError = validation;
      _confirming = validation == null;
    });
  }

  Widget _summary() {
    final settlement = widget.settlement;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${SettlementStrings.beneficiary}: '
            '${SettlementStrings.kind(settlement.beneficiaryKindCode)} '
            '${PaymentStrings.shortId(settlement.beneficiaryId)}',
            style: const TextStyle(color: AppTheme.ink),
          ),
          Text(
            '${PaymentStrings.columnOrder} ${PaymentStrings.shortId(settlement.orderId)}'
            ' · ${PaymentStrings.columnPayment} ${PaymentStrings.shortId(settlement.paymentId)}',
            style: const TextStyle(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 6),
          const Text(SettlementStrings.amount,
              style: TextStyle(color: AppTheme.mutedText)),
          Text(AppFormats.cop(settlement.amount),
              style: const TextStyle(
                  color: AppTheme.forest,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context) => AlertDialog(
        title: Text(_confirming
            ? SettlementStrings.confirmTitle
            : SettlementStrings.markPaidTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_confirming) ...[
                const Text(SettlementStrings.markPaidIntro),
                const SizedBox(height: 12),
              ],
              _summary(),
              const SizedBox(height: 12),
              if (_confirming) ...[
                const Text(SettlementStrings.confirmBody),
                const SizedBox(height: 4),
                Text('"${_reference.text.trim()}"',
                    style: const TextStyle(
                        color: AppTheme.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ] else
                TextField(
                  controller: _reference,
                  autofocus: true,
                  maxLength: maxSettlementReferenceLength,
                  onChanged: (_) => setState(() => _referenceError = null),
                  onSubmitted: (_) => _next(),
                  decoration: InputDecoration(
                    labelText: SettlementStrings.referenceLabel,
                    hintText: SettlementStrings.referenceHint,
                    helperText: SettlementStrings.referenceHelp,
                    helperMaxLines: 2,
                    errorText: _referenceError,
                  ),
                ),
              const PaymentNotice(SettlementStrings.irreversibleWarning,
                  danger: true),
              errorMessage(),
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
            key: const Key('confirm-mark-paid'),
            onPressed: busy
                ? null
                : _confirming
                    ? () => submit<Settlement>(
                          () => widget.onSubmit(_reference.text.trim()),
                          errorText: settlementErrorText,
                        )
                    : _next,
            child: submitLabel(_confirming
                ? SettlementStrings.confirmMarkPaid
                : SettlementStrings.continueLabel),
          ),
        ],
      );
}
