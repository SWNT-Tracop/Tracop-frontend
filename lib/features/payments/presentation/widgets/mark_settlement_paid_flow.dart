import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/settlement.dart';
import '../providers/payment_backoffice_provider.dart';
import 'mark_settlement_paid_dialog.dart';
import 'payment_dialogs.dart';

/// Abre el diálogo, procesa el resultado y recarga los datos relacionados.
/// Usado por la lista de liquidaciones y por el detalle del pago.
Future<void> runMarkSettlementPaid(
    BuildContext context, WidgetRef ref, Settlement settlement) async {
  final repository = ref.read(paymentBackofficeRepositoryProvider);
  final outcome = await showDialog<Object>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MarkSettlementPaidDialog(
      settlement: settlement,
      onSubmit: (reference) => repository.markSettlementPaid(
          settlement.id, settlement.version, reference),
    ),
  );
  if (!context.mounted) return;
  if (outcome is DomainFailure) {
    await VersionConflictDialog.show(
      context,
      title: SettlementStrings.conflictTitle,
      body: SettlementStrings.conflictBody,
    );
  } else if (outcome is Settlement) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(SettlementStrings.markedPaid)));
  }
  // También al cancelar: el diálogo pudo mostrar "ya fue pagada".
  invalidateAfterSettlementChange(ref);
}
