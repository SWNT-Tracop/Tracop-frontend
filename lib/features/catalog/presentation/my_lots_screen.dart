import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/lot_interaction_widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/lot.dart' hide Category, Product;
import '../domain/lot_quantity.dart';
import 'lot_detail_screen.dart' show lotDetailProvider;
import 'lot_error_text.dart';
import 'providers/catalog_provider.dart';
import 'providers/lot_management_provider.dart';

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
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB3261E) : AppTheme.forest,
      ));
  }

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
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB3261E))
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _publish(Lot lot) async {
    final confirmed = await _confirm(
      title: 'Publicar lote',
      message:
          'El lote quedará visible para los compradores con la información actual.',
      action: 'Publicar',
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
        _showMessage('Lote publicado.');
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
    final confirmed = await _confirm(
      title: 'Cancelar lote',
      message:
          'El lote dejará de estar disponible y esta acción no se puede deshacer.',
      action: 'Cancelar lote',
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
        _showMessage('Lote cancelado.');
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
    final confirmed = await _confirm(
      title: 'Eliminar borrador',
      message: 'El borrador se eliminará de forma permanente.',
      action: 'Eliminar',
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
        _showMessage('Borrador eliminado.');
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
      'draft' => 'Borradores',
      'published' => 'Publicados',
      'cancelled' => 'Cancelados',
      _ => 'Todos',
    };
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
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
                                      'Mis lotes',
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
                                          ? 'Crea, publica y mantén al día tu oferta.'
                                          : 'Aquí puedes consultar los lotes de tu cuenta.',
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
                                  label: const Text('Nuevo lote'),
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
                                label: const Text('Nuevo lote'),
                              ),
                            ),
                          ],
                          if (isSeller) ...[
                            const SizedBox(height: 12),
                            Text('Ordenar por modificación',
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
                                      label: Text('Recientes')),
                                  ButtonSegment(
                                      value: false,
                                      icon: Icon(Icons.north_rounded),
                                      label: Text('Antiguos')),
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
                          duration: const Duration(milliseconds: 240),
                          child: Text(
                              '$filterLabel · ${visibleLots.length} ${visibleLots.length == 1 ? 'lote' : 'lotes'}',
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
                          final canSwipe = lot.status == 'draft' ||
                              lot.status == 'published' ||
                              lot.status == 'reserved';
                          return Dismissible(
                            key: ValueKey(
                                'swipe-${_statusFilter ?? 'all'}-${lot.id}'),
                            direction: !canSwipe
                                ? DismissDirection.none
                                : lot.status == 'draft'
                                    ? DismissDirection.endToStart
                                    : DismissDirection.startToEnd,
                            background: const _SwipeHint(
                                label: 'Cancelar',
                                icon: Icons.cancel_outlined,
                                color: Color(0xFFC75B58),
                                alignment: Alignment.centerLeft),
                            secondaryBackground: const _SwipeHint(
                                label: 'Publicar',
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
                              duration: const Duration(milliseconds: 280),
                              child: _LotCard(
                                key: ValueKey(
                                    '${_statusFilter ?? 'all'}-${lot.id}'),
                                lot: lot,
                                productName:
                                    productNames[lot.productId] ?? 'Producto',
                                busy: _busy,
                                onOpen: () => context.go('/lots/${lot.id}'),
                                onEdit: () =>
                                    context.go('/lotes/${lot.id}/editar'),
                                onPublish: () => _publish(lot),
                                onCancel: () => _cancel(lot),
                                onDelete: () => _delete(lot),
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

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(lot.status);
    final price = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$ ',
      decimalDigits: 0,
    ).format(int.tryParse(lot.unitPrice) ?? 0);
    final dateRange =
        '${DateFormat('d MMM', 'es_CO').format(lot.availableFrom.toLocal())}'
        ' – ${DateFormat('d MMM y', 'es_CO').format(lot.availableUntil.toLocal())}';

    final front = Material(
      color: Colors.white,
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
                      Text(
                        '${formatQuantityMilli(lot.quantityMilli)} ${lot.unit}'
                        ' · $price por ${lot.unit}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.ink.withValues(alpha: .72),
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_available_outlined,
                    size: 18, color: AppTheme.mutedText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Disponible $dateRange',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: .72),
                          fontSize: 14,
                        ),
                  ),
                ),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: .72),
                            fontSize: 14,
                          ),
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
                      tooltip: 'Ver lote',
                      onPressed: busy ? null : onOpen,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ),
                ),
                if (lot.status == 'draft') ...[
                  Expanded(
                    child: Center(
                      child: IconButton.filledTonal(
                        tooltip: 'Editar lote',
                        onPressed: busy ? null : onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filled(
                        tooltip: 'Publicar lote',
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
                        tooltip: 'Cancelar lote',
                        onPressed: busy ? null : onCancel,
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFFB3261E),
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
        Text('$productName · Detalles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.forest, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
            'Calidad: ${lot.qualityGrade?.isNotEmpty == true ? lot.qualityGrade : 'No especificada'}'),
        Text('Disponibilidad: $dateRange'),
        Text(
            '${formatQuantityMilli(lot.quantityMilli)} ${lot.unit} · $price por ${lot.unit}'),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver')),
          if (lot.status == 'published' || lot.status == 'reserved')
            TextButton.icon(
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar')),
          if (lot.status == 'draft')
            FilledButton.tonal(
                onPressed: busy ? null : onPublish,
                child: const Text('Publicar')),
          if (lot.status == 'draft')
            IconButton(
                tooltip: 'Eliminar borrador',
                onPressed: busy ? null : onDelete,
                color: const Color(0xFFB3261E),
                icon: const Icon(Icons.delete_outline)),
        ]),
        const Align(
            alignment: Alignment.centerRight,
            child: Text('Toca para volver',
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

({String label, Color foreground, Color background}) _statusStyle(
        String status) =>
    switch (status) {
      'published' => (
          label: 'Publicado',
          foreground: AppTheme.forest,
          background: AppTheme.mint,
        ),
      'draft' => (
          label: 'Borrador',
          foreground: const Color(0xFF704E00),
          background: const Color(0xFFFFF3CD),
        ),
      'reserved' => (
          label: 'Reservado',
          foreground: const Color(0xFF0D47A1),
          background: const Color(0xFFE3F2FD),
        ),
      'sold_out' => (
          label: 'Agotado',
          foreground: AppTheme.mutedText,
          background: const Color(0xFFF3F4F6),
        ),
      'cancelled' => (
          label: 'Cancelado',
          foreground: AppTheme.mutedText,
          background: const Color(0xFFF3F4F6),
        ),
      'expired' => (
          label: 'Vencido',
          foreground: AppTheme.mutedText,
          background: const Color(0xFFF3F4F6),
        ),
      _ => (
          label: status,
          foreground: AppTheme.mutedText,
          background: const Color(0xFFF3F4F6),
        ),
    };

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Color(0xFF704E00), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sin conexión. Puedes revisar tus lotes guardados; para publicar, cancelar o eliminar necesitas señal.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF553B00),
                      fontSize: 14,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _NonSellerState extends StatelessWidget {
  const _NonSellerState({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 48, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'Solo productores y proveedores pueden publicar lotes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explora la oferta disponible desde la búsqueda.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar lotes'),
              ),
            ],
          ),
        ),
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filtered
                    ? Icons.filter_alt_off_outlined
                    : Icons.inventory_2_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                filtered
                    ? 'No hay lotes en este estado.'
                    : 'Aún no tienes lotes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                filtered
                    ? 'Prueba con otro filtro para ver tus lotes.'
                    : 'Publica tu cosecha y aparece en la búsqueda de compradores.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (filtered) ...[
                OutlinedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear lote'),
                ),
                TextButton(
                    onPressed: onClearFilter, child: const Text('Ver todos')),
              ] else
                FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Publicar mi primer lote')),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tus lotes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Revisa tu conexión e intenta de nuevo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

class _LotSkeleton extends StatelessWidget {
  const _LotSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 142,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 240,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.outline.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.outline.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      );
}
