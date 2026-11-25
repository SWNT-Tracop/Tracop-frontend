import 'package:flutter/material.dart';

import '../../../../core/i18n/strings.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/settlement_filters.dart';

/// Estado (servidor) + beneficiario, periodo y búsqueda (cliente).
class SettlementFiltersBar extends StatefulWidget {
  const SettlementFiltersBar({
    super.key,
    required this.status,
    required this.filters,
    required this.onStatusChanged,
    required this.onChanged,
  });

  final SettlementStatusFilter status;
  final SettlementFilters filters;
  final ValueChanged<SettlementStatusFilter> onStatusChanged;
  final ValueChanged<SettlementFilters> onChanged;

  @override
  State<SettlementFiltersBar> createState() => _SettlementFiltersBarState();
}

class _SettlementFiltersBarState extends State<SettlementFiltersBar> {
  late final _search = TextEditingController(text: widget.filters.query);

  @override
  void didUpdateWidget(SettlementFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters.query != _search.text) {
      _search.text = widget.filters.query;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _group(String label, List<Widget> chips) {
    final style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w600);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [Text(label, style: style), ...chips],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: SettlementStrings.searchLabel,
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: PaymentStrings.clearFilters,
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        widget.onChanged(filters.copyWith(query: '')),
                  ),
          ),
          onChanged: (value) =>
              widget.onChanged(filters.copyWith(query: value)),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 10, children: [
          _group(SettlementStrings.filterStatus, [
            for (final (label, value) in const [
              (SettlementStrings.filterIssued, SettlementStatusFilter.issued),
              (SettlementStrings.filterPaid, SettlementStatusFilter.paid),
              (SettlementStrings.filterAll, SettlementStatusFilter.all),
            ])
              ChoiceChip(
                label: Text(label),
                selected: widget.status == value,
                onSelected: (_) => widget.onStatusChanged(value),
              ),
          ]),
          _group(SettlementStrings.filterKind, [
            for (final (label, value) in <(String, BeneficiaryKind?)>[
              (SettlementStrings.filterKindAll, null),
              for (final kind in BeneficiaryKind.selectable)
                (SettlementStrings.kind(kind.wire), kind),
            ])
              ChoiceChip(
                label: Text(label),
                selected: filters.kind == value,
                onSelected: (_) =>
                    widget.onChanged(filters.copyWith(kind: () => value)),
              ),
          ]),
          _group(SettlementStrings.filterPeriod, [
            for (final (label, value) in const [
              (SettlementStrings.periodAll, SettlementPeriod.all),
              (SettlementStrings.period7, SettlementPeriod.last7Days),
              (SettlementStrings.period30, SettlementPeriod.last30Days),
            ])
              ChoiceChip(
                label: Text(label),
                selected: filters.period == value,
                onSelected: (_) =>
                    widget.onChanged(filters.copyWith(period: value)),
              ),
          ]),
        ]),
      ],
    );
  }
}
