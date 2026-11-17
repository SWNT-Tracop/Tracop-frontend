import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/i18n/strings.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter(
      {super.key,
      required this.value,
      this.style,
      this.duration = const Duration(milliseconds: 320)});
  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration:
            MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration,
        curve: Curves.easeOutCubic,
        builder: (context, count, _) => Text('$count', style: style),
      );
}

class StatusFilterGrid extends StatelessWidget {
  const StatusFilterGrid(
      {super.key,
      required this.selected,
      required this.counts,
      required this.onSelected,
      this.compact = false});
  final String? selected;
  final Map<String?, int> counts;
  final ValueChanged<String?> onSelected;
  final bool compact;

  static const _filters = <(String?, String, IconData, Color)>[
    (null, MyLotsStrings.all, Icons.grid_view_rounded, AppTheme.forest),
    (
      'draft',
      MyLotsStrings.drafts,
      Icons.edit_note_rounded,
      AppTheme.draftAccent
    ),
    (
      'published',
      MyLotsStrings.published,
      Icons.check_circle_outline_rounded,
      AppTheme.primary
    ),
    (
      'cancelled',
      MyLotsStrings.cancelled,
      Icons.cancel_outlined,
      AppTheme.danger
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(children: [
        for (final filter in _filters)
          Expanded(
              child: Semantics(
                  button: true,
                  selected: selected == filter.$1,
                  label: '${filter.$2}, ${counts[filter.$1] ?? 0}',
                  child: IconButton(
                      onPressed: () => _choose(filter.$1),
                      tooltip: filter.$2,
                      icon: Badge(
                          label: Text('${counts[filter.$1] ?? 0}'),
                          child: Icon(filter.$3,
                              color: selected == filter.$1
                                  ? filter.$4
                                  : AppTheme.mutedText)))))
      ]);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 10) / 2;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final filter in _filters)
          SizedBox(
              width: cardWidth,
              child: _StatusFilterCard(
                title: filter.$2,
                count: counts[filter.$1] ?? 0,
                icon: filter.$3,
                color: filter.$4,
                selected: selected == filter.$1,
                onTap: () => _choose(filter.$1),
              ))
      ]);
    });
  }

  void _choose(String? value) {
    HapticFeedback.selectionClick();
    onSelected(selected == value ? null : value);
  }
}

class _StatusFilterCard extends StatelessWidget {
  const _StatusFilterCard(
      {required this.title,
      required this.count,
      required this.icon,
      required this.color,
      required this.selected,
      required this.onTap});
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? 1 : .985,
        duration: _motion(context, 240),
        curve: Curves.easeOutCubic,
        child: Material(
          color: selected
              ? color.withValues(alpha: .12)
              : Theme.of(context).colorScheme.surface,
          elevation: selected ? 2 : 1,
          shadowColor: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: _motion(context, 240),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: selected ? color : AppTheme.outline,
                      width: selected ? 2.5 : 1)),
              child: Row(children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      AnimatedCounter(
                          value: count,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: color, fontWeight: FontWeight.w800)),
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: AppTheme.ink)),
                    ])),
                if (selected) Icon(Icons.check_circle, color: color, size: 18),
              ]),
            ),
          ),
        ),
      );
}

class LotThumbnail extends StatelessWidget {
  const LotThumbnail(
      {super.key,
      required this.url,
      required this.heroTag,
      this.size = 64,
      this.icon = Icons.spa_outlined});
  final String? url;
  final String heroTag;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
          dimension: size,
          child: imageUrl == null || imageUrl.isEmpty
              ? _fallback(context)
              : Image.network(imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth:
                      (size * MediaQuery.devicePixelRatioOf(context)).round(),
                  frameBuilder: (context, child, frame, syncLoaded) =>
                      syncLoaded || frame != null ? child : _skeleton(context),
                  errorBuilder: (_, __, ___) => _fallback(context))),
    );
    return Hero(tag: heroTag, child: child);
  }

  Widget _skeleton(BuildContext context) => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))));
  Widget _fallback(BuildContext context) => ColoredBox(
      color: AppTheme.mint,
      child: Icon(icon, color: AppTheme.forest, size: size * .44));
}

class FlipLotCard extends StatefulWidget {
  const FlipLotCard(
      {super.key,
      required this.front,
      required this.back,
      this.initiallyAnimate = false});
  final Widget front;
  final Widget back;
  final bool initiallyAnimate;
  @override
  State<FlipLotCard> createState() => _FlipLotCardState();
}

class _FlipLotCardState extends State<FlipLotCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 340));
  bool _flipped = false;
  bool _didIntro = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initiallyAnimate &&
        !_didIntro &&
        !MediaQuery.disableAnimationsOf(context)) {
      _didIntro = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward().then((_) {
            if (mounted) _controller.reverse();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = _flipped ? 1 : 0;
    } else {
      _flipped ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final showBack = angle >= math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateY(angle),
            child: Material(
              elevation: _flipped ? 4 : 1,
              shadowColor: AppTheme.forest.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  onTap: _flip,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateY(showBack ? math.pi : 0),
                    child: Stack(children: [
                      showBack ? widget.back : widget.front,
                      Positioned(
                          right: 8,
                          top: 8,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .92),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.flip_rounded,
                                      size: 18, color: AppTheme.forest)))),
                    ]),
                  )),
            ),
          );
        },
      );
}

class ActivityTimelineItem extends StatelessWidget {
  const ActivityTimelineItem(
      {super.key,
      required this.title,
      required this.description,
      required this.metadata,
      required this.timeLabel,
      required this.icon,
      required this.color,
      required this.thumbnail,
      required this.onTap,
      this.index = 0});
  final String title, description, metadata, timeLabel;
  final IconData icon;
  final Color color;
  final Widget thumbnail;
  final VoidCallback onTap;
  final int index;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration:
          reduced ? Duration.zero : Duration(milliseconds: 240 + index * 35),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, (1 - value) * 8), child: child)),
      child: Card(
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    thumbnail,
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Icon(icon, color: color, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: color)))
                          ]),
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(metadata,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(timeLabel,
                              style: Theme.of(context).textTheme.labelSmall),
                        ])),
                  ])))),
    );
  }
}

Duration _motion(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: milliseconds);
