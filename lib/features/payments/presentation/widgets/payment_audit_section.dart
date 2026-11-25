import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/audit_entry.dart';
import '../payment_error_text.dart';
import '../providers/payment_backoffice_provider.dart';
import 'payment_states.dart';

/// Id corto sin romper con ids inesperadamente cortos.
String auditShortId(String id) =>
    id.length <= 8 ? id.toUpperCase() : PaymentStrings.shortId(id);

/// Actor de una entrada: rol en español e id corto (`null` si fue el
/// sistema).
({String role, String? shortId}) auditActor(AuditEntry entry) {
  final actorId = entry.actorId;
  if (actorId == null) return (role: PaymentStrings.auditSystem, shortId: null);
  final role = entry.actorRole.isEmpty
      ? PaymentStrings.auditSystem
      : RoleStrings.label(entry.actorRole);
  return (role: role, shortId: auditShortId(actorId));
}

/// "Por Finanzas TRACOP · ABCD1234" (o "Por Sistema").
String auditActorText(AuditEntry entry) {
  final actor = auditActor(entry);
  return PaymentStrings.auditActor(actor.role, actor.shortId);
}

/// Auditoría del pago (solo administración; quien la incluye decide el rol).
/// Muestra la primera página y sigue con "Cargar más" usando `nextCursor`.
class PaymentAuditSection extends ConsumerStatefulWidget {
  const PaymentAuditSection({super.key, required this.paymentId});
  final String paymentId;

  @override
  ConsumerState<PaymentAuditSection> createState() =>
      _PaymentAuditSectionState();
}

class _PaymentAuditSectionState extends ConsumerState<PaymentAuditSection> {
  final _more = <AuditEntry>[];

  /// Cursor de la siguiente página; `null` usa el de la primera página.
  String? _cursor;
  bool _exhausted = false;
  bool _loadingMore = false;
  String? _moreError;

  /// Incremented on every reset so a page requested before a reload is
  /// discarded instead of being appended with a stale cursor.
  int _generation = 0;

  void _reset() {
    _generation++;
    _loadingMore = false;
    _more.clear();
    _cursor = null;
    _exhausted = false;
    _moreError = null;
  }

  Future<void> _loadMore(String cursor) async {
    if (_loadingMore) return;
    final generation = _generation;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    final result = await ref.read(paymentBackofficeRepositoryProvider).audit(
        entity: AuditTargets.payment,
        entityId: widget.paymentId,
        cursor: cursor);
    if (!mounted || generation != _generation) return;
    setState(() {
      _loadingMore = false;
      switch (result) {
        case Ok(value: final page):
          final known = {..._more.map((entry) => entry.id)};
          _more.addAll(page.items.where((entry) => known.add(entry.id)));
          _cursor = page.nextCursor;
          _exhausted = page.nextCursor == null;
        case Err(error: final failure):
          _moreError = paymentErrorText(failure);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(paymentAuditProvider(widget.paymentId), (previous, next) {
      // Una primera página nueva (recarga) descarta las siguientes.
      if (next.hasValue && previous?.valueOrNull != next.valueOrNull) {
        setState(_reset);
      }
    });
    final async = ref.watch(paymentAuditProvider(widget.paymentId));
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('payment-audit-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PaymentStrings.auditTitle,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${PaymentStrings.auditHint} ${PaymentStrings.bogotaTimeNote}',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText)),
        const SizedBox(height: 12),
        async.when(
          skipLoadingOnReload: true,
          loading: () => const PaymentLoadingSkeleton(rows: 2),
          error: (error, _) => PaymentErrorState(
            title: PaymentStrings.auditLoadError,
            message: error is DomainFailure
                ? paymentErrorText(error)
                : PaymentStrings.auditLoadError,
            onRetry: () =>
                ref.invalidate(paymentAuditProvider(widget.paymentId)),
          ),
          data: (page) {
            final entries = [...page.items, ..._more];
            final next = _exhausted ? null : (_cursor ?? page.nextCursor);
            if (entries.isEmpty) {
              return Text(PaymentStrings.auditEmpty,
                  style: textTheme.bodyMedium);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in entries) AuditEntryTile(entry: entry),
                if (_moreError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_moreError!,
                        style: const TextStyle(color: AppTheme.dangerStrong)),
                  ),
                if (next != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('audit-load-more'),
                      onPressed: _loadingMore ? null : () => _loadMore(next),
                      icon: _loadingMore
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.expand_more),
                      label: const Text(PaymentStrings.auditLoadMore),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class AuditEntryTile extends StatelessWidget {
  const AuditEntryTile({super.key, required this.entry});
  final AuditEntry entry;

  String _status(String wire) => entry.entity == AuditTargets.settlement
      ? SettlementStrings.status(wire)
      : PaymentStrings.status(wire);

  @override
  Widget build(BuildContext context) {
    final before = entry.beforeStatus;
    final after = entry.afterStatus;
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppTheme.mutedText);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PaymentStrings.auditAction(entry.action),
              style: const TextStyle(
                  color: AppTheme.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(auditActorText(entry),
              style: const TextStyle(color: AppTheme.ink)),
          if (before != null || after != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  [
                    if (before != null) _status(before),
                    if (after != null) _status(after),
                  ].join(' → '),
                  style: const TextStyle(color: AppTheme.ink)),
            ),
          const SizedBox(height: 2),
          Text(AppFormats.bogotaDateTime(entry.at), style: muted),
        ],
      ),
    );
  }
}
