import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/utils/text_search.dart';

@immutable
class SelectorOption<T> {
  const SelectorOption(
      {required this.value, required this.label, this.subtitle, this.icon});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Searchable, touch-friendly selector. Values remain the caller's domain/API values.
class SearchableSheetSelector<T> extends StatelessWidget {
  const SearchableSheetSelector({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = 'Selecciona',
    this.emptyLabel = 'Sin resultados',
    this.clearLabel,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final List<SelectorOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final String emptyLabel;
  final String? clearLabel;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected =
        options.where((option) => option.value == value).firstOrNull;
    return Semantics(
      button: true,
      label: '$label: ${selected?.label ?? hint}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            onTap: enabled ? () => _open(context) : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                border: Border.all(
                    color: errorText == null
                        ? AppTheme.outline
                        : Theme.of(context).colorScheme.error),
              ),
              child: Row(children: [
                Expanded(
                    child: Text(selected?.label ?? label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: selected == null
                                  ? Theme.of(context).hintColor
                                  : Theme.of(context).colorScheme.onSurface,
                            ))),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded),
              ]),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(errorText!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error))),
      ]),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _SelectorSheet<T>(
        label: label,
        options: options,
        selected: value,
        emptyLabel: emptyLabel,
        clearLabel: clearLabel,
      ),
    );
    if (result == _clearSelection) {
      onChanged(null);
    } else if (result != null) {
      onChanged(result as T);
    }
  }
}

const _clearSelection = Object();

class _SelectorSheet<T> extends StatefulWidget {
  const _SelectorSheet(
      {required this.label,
      required this.options,
      required this.selected,
      required this.emptyLabel,
      this.clearLabel});
  final String label;
  final List<SelectorOption<T>> options;
  final T? selected;
  final String emptyLabel;
  final String? clearLabel;

  @override
  State<_SelectorSheet<T>> createState() => _SelectorSheetState<T>();
}

class _SelectorSheetState<T> extends State<_SelectorSheet<T>> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = foldForSearch(_search.text);
    final visible = widget.options
        .where((option) => foldForSearch(option.label).contains(query))
        .toList(growable: false);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Buscar', prefixIcon: Icon(Icons.search_rounded)),
          ),
          if (widget.clearLabel != null)
            ListTile(
                minLeadingWidth: 40,
                leading: const Icon(Icons.all_inclusive_rounded),
                title: Text(widget.clearLabel!),
                onTap: () => Navigator.pop(context, _clearSelection)),
          const SizedBox(height: 8),
          Expanded(
              child: visible.isEmpty
                  ? Center(child: Text(widget.emptyLabel))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final option = visible[index];
                        final selected = option.value == widget.selected;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            selected: selected,
                            button: true,
                            label: option.label,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              color: selected
                                  ? AppTheme.mint
                                  : Theme.of(context).colorScheme.surface,
                              child: ListTile(
                                minTileHeight: 56,
                                leading: option.icon == null
                                    ? null
                                    : Icon(option.icon),
                                title: Text(option.label),
                                subtitle: option.subtitle == null
                                    ? null
                                    : Text(option.subtitle!),
                                trailing: selected
                                    ? const Icon(Icons.check_circle,
                                        color: AppTheme.forest)
                                    : null,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context, option.value);
                                },
                              ),
                            ),
                          ),
                        );
                      })),
        ]),
      ),
    );
  }
}

class OptionCircleSelector<T> extends StatelessWidget {
  const OptionCircleSelector(
      {super.key,
      required this.options,
      required this.value,
      required this.onChanged,
      this.columns = 2});
  final List<SelectorOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final int columns;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final count =
            constraints.maxWidth > 600 ? options.length.clamp(2, 4) : columns;
        return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final selected = option.value == value;
              final width = (constraints.maxWidth - 10 * (count - 1)) / count;
              return SizedBox(
                  width: width,
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: option.label,
                    child: AnimatedScale(
                      scale: selected ? 1 : .97,
                      duration: _motionDuration(context, 240),
                      curve: Curves.easeOutCubic,
                      child: Material(
                        color: selected
                            ? AppTheme.mint
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(option.value);
                          },
                          child: AnimatedContainer(
                            duration: _motionDuration(context, 240),
                            curve: Curves.easeOutCubic,
                            constraints: const BoxConstraints(minHeight: 88),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selected
                                        ? AppTheme.primary
                                        : AppTheme.outline,
                                    width: selected ? 2 : 1)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (option.icon != null)
                                    Icon(option.icon,
                                        color: selected
                                            ? AppTheme.forest
                                            : AppTheme.mutedText),
                                  const SizedBox(height: 6),
                                  Text(option.label,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              color: selected
                                                  ? AppTheme.forest
                                                  : AppTheme.ink)),
                                  if (selected)
                                    const Icon(Icons.check_circle,
                                        size: 18, color: AppTheme.forest),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ));
            }).toList());
      });
}

class OptionCardGrid<T> extends StatelessWidget {
  const OptionCardGrid(
      {super.key,
      required this.options,
      required this.value,
      required this.onChanged});
  final List<SelectorOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => OptionCircleSelector<T>(
      options: options, value: value, onChanged: onChanged, columns: 2);
}

class StepperField extends StatelessWidget {
  const StepperField(
      {super.key,
      required this.value,
      required this.onChanged,
      this.step = 1,
      this.minimum = 0,
      this.label = 'Cantidad'});
  final double value;
  final ValueChanged<double> onChanged;
  final double step, minimum;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      value: '$value',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton.filledTonal(
            onPressed: value <= minimum
                ? null
                : () =>
                    onChanged((value - step).clamp(minimum, double.infinity)),
            icon: const Icon(Icons.remove),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedSwitcher(
                duration: _motionDuration(context, 220),
                child: Text('$value',
                    key: ValueKey(value),
                    style: Theme.of(context).textTheme.titleMedium))),
        IconButton.filledTonal(
            onPressed: () => onChanged(value + step),
            icon: const Icon(Icons.add),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
      ]));
}

class AnimatedStatusTimeline extends StatelessWidget {
  const AnimatedStatusTimeline({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<SelectorOption<String>> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Estado del pedido: ${steps[currentIndex].label}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: _motionDuration(context, 280),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: index <= currentIndex
                            ? AppTheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index <= currentIndex
                              ? AppTheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Icon(
                        index < currentIndex
                            ? Icons.check_rounded
                            : (steps[index].icon ?? Icons.circle),
                        size: 18,
                        color: index <= currentIndex
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(steps[index].label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 17),
                    child: AnimatedContainer(
                      duration: _motionDuration(context, 280),
                      height: 2,
                      color: index < currentIndex
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
}

class StepFormScaffold extends StatelessWidget {
  const StepFormScaffold({
    super.key,
    required this.title,
    required this.steps,
    required this.currentStep,
    required this.onBack,
    required this.onNext,
    required this.child,
    this.nextLabel = 'Continuar',
    this.backLabel = 'Atrás',
    this.canContinue = true,
  });

  final String title;
  final List<String> steps;
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Widget child;
  final String nextLabel;
  final String backLabel;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final motion = _motionDuration(context, 320);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      'Paso ${currentStep + 1} de ${steps.length}: ${steps[currentStep]}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        duration: motion,
                        curve: Curves.easeOutCubic,
                        tween: Tween(end: (currentStep + 1) / steps.length),
                        builder: (context, value, _) =>
                            LinearProgressIndicator(value: value, minHeight: 6),
                      )),
                ]),
          ),
          Expanded(
              child: AnimatedSwitcher(
            duration: motion,
            switchInCurve: Curves.easeOutCubic,
            child: KeyedSubtree(key: ValueKey(currentStep), child: child),
          )),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              if (currentStep > 0)
                Expanded(
                    child: OutlinedButton(
                        onPressed: onBack, child: Text(backLabel))),
              if (currentStep > 0) const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: canContinue ? onNext : null,
                      child: Text(nextLabel))),
            ]),
          ),
        ]),
      ),
    );
  }
}

Duration _motionDuration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: milliseconds);
