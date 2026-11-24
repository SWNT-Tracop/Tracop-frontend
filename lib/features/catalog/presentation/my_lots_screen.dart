import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/config/catalog_config.dart';
import '../../../core/i18n/formats.dart';
import '../../../core/i18n/strings.dart';
import '../../../shared/widgets/lot_interaction_widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/lot.dart' hide Category, Product;
import '../domain/lot_quantity.dart';
import 'lot_detail_screen.dart' show lotDetailProvider;
import 'lot_error_text.dart';
import 'providers/catalog_provider.dart';
import 'providers/lot_management_provider.dart';

typedef _S = MyLotsStrings;

class MyLotsScreen extends ConsumerStatefulWidget {
  const MyLotsScreen({super.key});

  @override
  ConsumerState<MyLotsScreen> createState() => _MyLotsScreenState();
}

class _MyLotsScreenState extends ConsumerState<MyLotsScreen> {
  String? _statusFilter;
  bool _initialized = false;
  bool _busy = false;
  bool _sortNewestFirst = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final uri = GoRouterState.of(context).uri;
    _statusFilter = uri.queryParameters['status'];
    if (uri.queryParameters['intent'] == 'create') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/lotes/nuevo');
      });
    }
  }

  void _refresh() {
    ref.invalidate(myLotsProvider);
    ref.invalidate(homeLotsProvider);
    ref.invalidate(lotDetailProvider);
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: AppMotion.snackBar,
        content: Text(message),
        backgroundColor: error ? AppTheme.dangerStrong : AppTheme.forest,
      ));
  }

  bool get _offline => ref.read(homeConnectivityProvider).valueOrNull == false;

  void _rememberModification(String lotId) {
    ref.read(localLotModifiedAtProvider.notifier).state = {
      ...ref.read(localLotModifiedAtProvider),
      lotId: DateTime.now(),
    };
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(CommonStrings.back),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppTheme.dangerStrong)
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _publish(Lot lot) async {
    if (_busy) return;
    final confirmed = await _confirm(
      title: _S.publishTitle,
      message: _S.publishBody,
      action: _S.publish,
    );
    if (!confirmed || _busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(catalogRepositoryProvider)
        .publishLot(lot.id, lot.version);
    if (!mounted) return;
    setState(() => _busy = false);
    result.map(
      ok: (_) {
        _rememberModification(lot.id);
        _showMessage(_offline ? _S.publishedPending : _S.published1);
        ref.invalidate(lotByIdProvider(lot.id));
        _refresh();
      },
      err: (failure) => _showMessage(
        lotErrorText(failure.error),
        error: true,
      ),
    );
  }

  Future<void> _cancel(Lot lot) async {
    if (_busy) return;
    final confirmed = await _confirm(
      title: _S.cancelTitle,
      message: _S.cancelBody,
      action: _S.cancelTitle,
      destructive: true,
    );
    if (!confirmed || _busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(catalogRepositoryProvider)
        .cancelLot(lot.id, lot.version);
    if (!mounted) return;
    setState(() => _busy = false);
    result.map(
      ok: (_) {
        _rememberModification(lot.id);
        _showMessage(_offline ? _S.cancelledPending : _S.cancelled1);
        ref.invalidate(lotByIdProvider(lot.id));
        _refresh();
      },
      err: (failure) => _showMessage(
        lotErrorText(failure.error),
        error: true,
      ),
    );
  }

  Future<void> _delete(Lot lot) async {
    if (_busy) return;
    final confirmed = await _confirm(
      title: _S.deleteTitle,
      message: _S.deleteBody,
      action: _S.delete,
      destructive: true,
    );
    if (!confirmed || _busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(catalogRepositoryProvider)
        .deleteLot(lot.id, lot.version);
    if (!mounted) return;
    setState(() => _busy = false);
    result.map(
      ok: (_) {
        final modifiedAt =
            Map<String, DateTime>.of(ref.read(localLotModifiedAtProvider))
              ..remove(lot.id);
        ref.read(localLotModifiedAtProvider.notifier).state = modifiedAt;
        _showMessage(_offline ? _S.deletedPending : _S.deleted);
        ref.invalidate(lotByIdProvider(lot.id));
        _refresh();
      },
      err: (failure) => _showMessage(
        lotErrorText(failure.error),
        error: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeConnectivityProvider, (previous, next) {
      if (previous?.valueOrNull == false && next.valueOrNull == true) {
        _refresh();
      }
    });

    final role = ref.watch(homeUserProvider).valueOrNull?.role ??
        ref.watch(authProvider).valueOrNull?.user.role;
    final isSeller = role == 'producer' || role == 'supplier';
    final lots = ref.watch(myLotsProvider);
    final products = ref.watch(catalogProductsProvider).valueOrNull ?? const [];
    final productNames = {for (final p in products) p.id: p.name};
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    final allLots = lots.valueOrNull ?? const <Lot>[];
    final localModifiedAt = ref.watch(localLotModifiedAtProvider);
    final outboxStatuses = ref.watch(lotSyncStatusesProvider).valueOrNull ??
        const <String, String>{};
    final originalOrder = {
      for (var i = 0; i < allLots.length; i++) allLots[i].id: i
    };
    final orderedLots = List<Lot>.of(allLots)
      ..sort((a, b) {
        final aModified = localModifiedAt[a.id];
        final bModified = localModifiedAt[b.id];
        int comparison;
        if (aModified != null && bModified != null) {
          comparison = aModified.compareTo(bModified);
        } else if (aModified != null) {
          comparison = 1;
        } else if (bModified != null) {
          comparison = -1;
        } else {
          comparison = originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
        }
        return _sortNewestFirst ? -comparison : comparison;
      });
    final visibleLots = _statusFilter == null
        ? orderedLots
        : orderedLots.where((lot) => lot.status == _statusFilter).toList();
    final statusCounts = <String?, int>{
      null: allLots.length,
      'draft': allLots.where((lot) => lot.status == 'draft').length,
      'published': allLots.where((lot) => lot.status == 'published').length,
      'cancelled': allLots.where((lot) => lot.status == 'cancelled').length,
    };
    final filterLabel = switch (_statusFilter) {
      'draft' => _S.drafts,
      'published' => _S.published,
      'cancelled' => _S.cancelled,
      _ => _S.all,
    };
    final wide =
        MediaQuery.sizeOf(context).width >= CatalogConfig.wideBreakpoint;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: CatalogConfig.maxContentWidth),
            child: RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await ref
                    .read(myLotsProvider.future)
                    .catchError((_) => <Lot>[]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        wide ? 40 : 20, wide ? 36 : 20, wide ? 40 : 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _S.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppTheme.forest,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isSeller
                                          ? _S.sellerSubtitle
                                          : _S.buyerSubtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.ink
                                                .withValues(alpha: .72),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSeller && wide) ...[
                                const SizedBox(width: 16),
                                FilledButton.icon(
                                  onPressed: () => context.go('/lotes/nuevo'),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text(_S.newLot),
                                ),
                              ],
                            ],
                          ),
                          if (isSeller && !wide) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => context.go('/lotes/nuevo'),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text(_S.newLot),
                              ),
                            ),
                          ],
                          if (isSeller) ...[
                            const SizedBox(height: 12),
                            Text(_S.sortByChange,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: AppTheme.ink)),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SegmentedButton<bool>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                      value: true,
                                      icon: Icon(Icons.south_rounded),
                                      label: Text(_S.newest)),
                                  ButtonSegment(
                                      value: false,
                                      icon: Icon(Icons.north_rounded),
                                      label: Text(_S.oldest)),
                                ],
                                selected: {_sortNewestFirst},
                                onSelectionChanged: (selection) => setState(
                                    () => _sortNewestFirst = selection.first),
                              ),
                            ),
                          ],
                          if (offline) ...[
                            const SizedBox(height: 16),
                            const _OfflineNotice(),
                          ],
                          // Progreso visible mientras se publica o cancela.
                          AnimatedSwitcher(
                            duration: AppMotion.of(context, AppMotion.fast),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: LinearProgressIndicator(
                                        semanticsLabel: _S.working),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSeller)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StatusFilterHeader(
                        selected: _statusFilter,
                        counts: statusCounts,
                        onSelected: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ),
                  if (isSeller && !(lots.isLoading && allLots.isEmpty))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            wide ? 40 : 20, 14, wide ? 40 : 20, 4),
                        child: AnimatedSwitcher(
                          duration: AppMotion.of(context, AppMotion.fast),
                          child: Text(
                              _S.heading(filterLabel, visibleLots.length),
                              key: ValueKey(
                                  'filter-heading-$_statusFilter-${visibleLots.length}'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: AppTheme.forest,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  if (!isSeller)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NonSellerState(
                        onSearch: () => context.go('/buscar'),
                      ),
                    )
                  else if (lots.isLoading && allLots.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20),
                      sliver: SliverList.builder(
                        itemCount: 3,
                        itemBuilder: (_, __) => const _LotSkeleton(),
                      ),
                    )
                  else if (lots.hasError && allLots.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(onRetry: _refresh),
                    )
                  else if (visibleLots.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        filtered: _statusFilter != null,
                        onCreate: () => context.go('/lotes/nuevo'),
                        onClearFilter: () =>
                            setState(() => _statusFilter = null),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          wide ? 40 : 20, 8, wide ? 40 : 20, 32),
                      sliver: SliverList.separated(
                        itemCount: visibleLots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final lot = visibleLots[index];
                          final canSwipe = !_busy &&
                              (lot.status == 'draft' ||
                                  lot.status == 'published' ||
                                  lot.status == 'reserved');
                          return Dismissible(
                            key: ValueKey(
                                'swipe-${_statusFilter ?? 'all'}-${lot.id}'),
                            direction: !canSwipe
                                ? DismissDirection.none
                                : lot.status == 'draft'
                                    ? DismissDirection.endToStart
                                    : DismissDirection.startToEnd,
                            background: const _SwipeHint(
                                label: _S.cancel,
                                icon: Icons.cancel_outlined,
                                color: AppTheme.danger,
                                alignment: Alignment.centerLeft),
                            secondaryBackground: const _SwipeHint(
                                label: _S.publish,
                                icon: Icons.publish_rounded,
                                color: AppTheme.primary,
                                alignment: Alignment.centerRight),
                            confirmDismiss: (_) async {
                              if (lot.status == 'draft') {
                                await _publish(lot);
                              } else {
                                await _cancel(lot);
                              }
                              return false;
                            },
                            child: AnimatedSwitcher(
                              duration: AppMotion.of(context, AppMotion.medium),
                              child: _LotCard(
                                key: ValueKey(
                                    '${_statusFilter ?? 'all'}-${lot.id}'),
                                lot: lot,
                                productName: productNames[lot.productId] ??
                                    LotStrings.productFallback,
                                busy: _busy,
                                onOpen: () => context.go('/lots/${lot.id}'),
                                onEdit: () =>
                                    context.go('/lotes/${lot.id}/editar'),
                                onPublish: () => _publish(lot),
                                onCancel: () => _cancel(lot),
                                onDelete: () => _delete(lot),
                                syncStatus: outboxStatuses[lot.id] ??
                                    (localModifiedAt.containsKey(lot.id)
                                        ? 'synchronized'
                                        : null),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint(
      {required this.label,
      required this.icon,
      required this.color,
      required this.alignment});
  final String label;
  final IconData icon;
  final Color color;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: alignment,
        decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700))
        ]),
      );
}

class _StatusFilterHeader extends SliverPersistentHeaderDelegate {
  _StatusFilterHeader(
      {required this.selected, required this.counts, required this.onSelected});
  final String? selected;
  final Map<String?, int> counts;
  final ValueChanged<String?> onSelected;
  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 202;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(
        child: Material(
          color: AppTheme.background,
          elevation: overlapsContent ? 2 : 0,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: StatusFilterGrid(
                selected: selected,
                counts: counts,
                onSelected: onSelected,
                compact: shrinkOffset > 35,
              )),
        ),
      );
  @override
  bool shouldRebuild(covariant _StatusFilterHeader oldDelegate) =>
      selected != oldDelegate.selected || counts != oldDelegate.counts;
}

class _LotCard extends StatelessWidget {
  const _LotCard({
    required this.lot,
    required this.productName,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onPublish,
    required this.onCancel,
    required this.onDelete,
    this.syncStatus,
    super.key,
  });

  final Lot lot;
  final String productName;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final String? syncStatus;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(lot.status);
    final price = AppFormats.moneyText(lot.unitPrice);
    final dateRange = LotStrings.dateRange(
        AppFormats.dayMonth(lot.availableFrom),
        AppFormats.dayMonthYear(lot.availableUntil));
    final quantity =
        LotStrings.quantity(formatQuantityMilli(lot.quantityMilli), lot.unit);
    final summary = '$quantity · ${LotStrings.pricePer(price, lot.unit)}';
    final mutedStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.ink.withValues(alpha: .72),
          fontSize: 14,
        );

    final front = Material(
      color: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LotThumbnail(
                    url: lot.photos.firstOrNull?.url,
                    heroTag: 'lot-photo-${lot.id}',
                    size: 60),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(summary, style: mutedStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  // Deja espacio al icono de voltear.
                  padding: const EdgeInsets.only(right: 32),
                  child: _StatusBadge(status: status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (syncStatus != null) ...[
              _LotSyncBadge(status: syncStatus!),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                const Icon(Icons.event_available_outlined,
                    size: 18, color: AppTheme.mutedText),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_S.available(dateRange), style: mutedStyle)),
              ],
            ),
            if (lot.qualityGrade?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 18, color: AppTheme.mutedText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lot.qualityGrade!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mutedStyle,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      tooltip: _S.view,
                      onPressed: busy ? null : onOpen,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ),
                ),
                if (lot.status == 'draft') ...[
                  Expanded(
                    child: Center(
                      child: IconButton.filledTonal(
                        tooltip: _S.edit,
                        onPressed: busy ? null : onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filled(
                        tooltip: _S.publishTitle,
                        onPressed: busy ? null : onPublish,
                        icon: const Icon(Icons.publish_rounded),
                      ),
                    ),
                  ),
                ],
                if (lot.status == 'published' || lot.status == 'reserved')
                  Expanded(
                    child: Center(
                      child: IconButton(
                        tooltip: _S.cancelTitle,
                        onPressed: busy ? null : onCancel,
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.dangerStrong,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                    ),
                  ),
                if (lot.status == 'published' || lot.status == 'reserved')
                  const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
    final back = Container(
      constraints: const BoxConstraints(minHeight: 180),
      color: AppTheme.mint,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(LotStrings.detailsTitle(productName),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.forest, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(LotStrings.quality(lot.qualityGrade?.isNotEmpty == true
            ? lot.qualityGrade!
            : LotStrings.noQuality)),
        Text(_S.availability(dateRange)),
        Text(summary),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text(_S.viewShort)),
          if (lot.status == 'published' || lot.status == 'reserved')
            TextButton.icon(
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(_S.cancel)),
          if (lot.status == 'draft')
            FilledButton.tonal(
                onPressed: busy ? null : onPublish,
                child: const Text(_S.publish)),
          if (lot.status == 'draft')
            IconButton(
                tooltip: _S.deleteTitle,
                onPressed: busy ? null : onDelete,
                color: AppTheme.dangerStrong,
                icon: const Icon(Icons.delete_outline)),
        ]),
        const Align(
            alignment: Alignment.centerRight,
            child: Text(LotStrings.tapToFlipBack,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText))),
      ]),
    );
    return FlipLotCard(front: front, back: back);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ({String label, Color foreground, Color background}) status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: status.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _LotSyncBadge extends StatelessWidget {
  const _LotSyncBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      'pending' => (
          'Pendiente de sincronización',
          Icons.schedule,
          AppTheme.warningIcon
        ),
      'conflict' => (
          'Conflicto: revisar sincronización',
          Icons.warning_amber,
          AppTheme.dangerStrong
        ),
      'rejected' => (
          'No se pudo sincronizar',
          Icons.error_outline,
          AppTheme.dangerStrong
        ),
      _ => ('Sincronizado', Icons.cloud_done_outlined, AppTheme.forest),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

({String label, Color foreground, Color background}) _statusStyle(
    String status) {
  final label = LotStatusStrings.owner(status);
  return switch (status) {
    'published' => (
        label: label,
        foreground: AppTheme.forest,
        background: AppTheme.mint,
      ),
    'draft' => (
        label: label,
        foreground: AppTheme.warningIcon,
        background: AppTheme.warningSurface,
      ),
    'reserved' => (
        label: label,
        foreground: AppTheme.infoText,
        background: AppTheme.infoSurface,
      ),
    _ => (
        label: label,
        foreground: AppTheme.mutedText,
        background: AppTheme.neutralSurface,
      ),
  };
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.warningSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppTheme.warningIcon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _S.offline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warningText,
                      fontSize: 14,
                    ),
              ),
            ),
          ],
        ),
      );
}

// Estado centrado con icono, titulo, texto y acciones.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.iconColor = AppTheme.primary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ...actions,
            ],
          ),
        ),
      );
}

class _NonSellerState extends StatelessWidget {
  const _NonSellerState({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => _MessageState(
        icon: Icons.storefront_outlined,
        title: _S.onlySellers,
        body: _S.exploreOffer,
        actions: [
          FilledButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Text(_S.searchLots),
          ),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filtered,
    required this.onCreate,
    required this.onClearFilter,
  });

  final bool filtered;
  final VoidCallback onCreate;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) => _MessageState(
        icon: filtered
            ? Icons.filter_alt_off_outlined
            : Icons.inventory_2_outlined,
        title: filtered ? _S.emptyFiltered : _S.empty,
        body: filtered ? _S.emptyFilteredBody : _S.emptyBody,
        actions: filtered
            ? [
                OutlinedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(_S.createLot),
                ),
                TextButton(
                    onPressed: onClearFilter, child: const Text(_S.seeAll)),
              ]
            : [
                FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(_S.firstLot)),
              ],
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageState(
        icon: Icons.cloud_off_outlined,
        iconColor: AppTheme.mutedText,
        title: _S.loadError,
        body: _S.loadErrorBody,
        actions: [
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(CommonStrings.retry),
          ),
        ],
      );
}

class _LotSkeleton extends StatelessWidget {
  const _LotSkeleton();

  Widget _bar(double width, double alpha) => Container(
        width: width,
        height: 14,
        decoration: BoxDecoration(
          color: AppTheme.outline.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(8),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        height: 142,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(180, 1),
            const SizedBox(height: 12),
            _bar(240, .7),
            const SizedBox(height: 24),
            _bar(160, .5),
          ],
        ),
      );
}
