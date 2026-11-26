import 'package:flutter/material.dart';

import '../../../../core/i18n/strings.dart';
import '../../domain/entities/payment.dart';
import '../../domain/review_filters.dart';

class PaymentFilters extends StatefulWidget {
  const PaymentFilters(
      {super.key, required this.filters, required this.onChanged});
  final ReviewFilters filters;
  final ValueChanged<ReviewFilters> onChanged;

  @override
  State<PaymentFilters> createState() => _PaymentFiltersState();
}

class _PaymentFiltersState extends State<PaymentFilters> {
  late final _search = TextEditingController(text: widget.filters.query);

  @override
  void didUpdateWidget(PaymentFilters oldWidget) {
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

  Widget _chip<T>(String label, T? value, T? current, ValueChanged<T?> onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: value == current,
        onSelected: (_) => onTap(value),
      );

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: PaymentStrings.searchLabel,
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
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(PaymentStrings.filterStatus, style: labelStyle),
                for (final option in const <(String, PaymentStatus?)>[
                  (PaymentStrings.filterAll, null),
                  (PaymentStrings.filterProofs, PaymentStatus.proofUploaded),
                  (PaymentStrings.filterDisputes, PaymentStatus.disputed),
                ])
                  _chip<PaymentStatus>(
                      option.$1,
                      option.$2,
                      filters.status,
                      (value) => widget
                          .onChanged(filters.copyWith(status: () => value))),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(PaymentStrings.filterMethod, style: labelStyle),
                _chip<PaymentMethod>(
                    PaymentStrings.filterAll,
                    null,
                    filters.method,
                    (value) => widget
                        .onChanged(filters.copyWith(method: () => value))),
                for (final method in PaymentMethod.selectable)
                  _chip<PaymentMethod>(
                      PaymentStrings.method(method.wire),
                      method,
                      filters.method,
                      (value) => widget
                          .onChanged(filters.copyWith(method: () => value))),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
