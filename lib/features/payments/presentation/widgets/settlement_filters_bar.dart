import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/formats.dart';
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

  /// Calendario en español (la app fija `es_CO`) sobre la fecha de emisión.
  Future<void> _pickRange() async {
    final filters = widget.filters;
    final today = AppFormats.toBogota(DateTime.now());
    final last = DateTime(today.year, today.month, today.day);
    final current = filters.range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: last,
      initialDateRange: current == null || current.end.isAfter(last)
          ? null
          : DateTimeRange(
              start: DateTime(
                  current.start.year, current.start.month, current.start.day),
              end: DateTime(
                  current.end.year, current.end.month, current.end.day)),
      helpText: SettlementStrings.rangePickerHelp,
    );
    if (picked == null || !mounted) return;
    widget.onChanged(filters
        .withRange(SettlementDateRange(start: picked.start, end: picked.end)));
  }

  static String _day(DateTime day) =>
      DateFormat('d MMM y', AppFormats.locale).format(day);

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final range = filters.range;
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
                selected: range == null && filters.period == value,
                onSelected: (_) => widget.onChanged(filters.withPeriod(value)),
              ),
            if (range == null)
              ActionChip(
                key: const Key('settlement-range-pick'),
                avatar: const Icon(Icons.date_range_outlined, size: 18),
                label: const Text(SettlementStrings.periodRange),
                onPressed: _pickRange,
              )
            else
              InputChip(
                key: const Key('settlement-range-chip'),
                avatar: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(SettlementStrings.periodRangeLabel(
                    _day(range.start), _day(range.end))),
                selected: true,
                showCheckmark: false,
                onPressed: _pickRange,
                onDeleted: () => widget.onChanged(filters.withRange(null)),
                deleteButtonTooltipMessage: SettlementStrings.clearRange,
              ),
          ]),
        ]),
      ],
    );
  }
}
