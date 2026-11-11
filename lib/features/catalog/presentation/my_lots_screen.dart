import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
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
    final visibleLots = _statusFilter == null
        ? allLots
        : allLots.where((lot) => lot.status == _statusFilter).toList();
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
                          if (offline) ...[
                            const SizedBox(height: 16),
                            const _OfflineNotice(),
                          ],
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusFilterChip(
                                label: 'Todos',
                                selected: _statusFilter == null,
                                onTap: () =>
                                    setState(() => _statusFilter = null),
                              ),
                              _StatusFilterChip(
                                label: 'Borradores',
                                selected: _statusFilter == 'draft',
                                onTap: () =>
                                    setState(() => _statusFilter = 'draft'),
                              ),
                              _StatusFilterChip(
                                label: 'Publicados',
                                selected: _statusFilter == 'published',
                                onTap: () =>
                                    setState(() => _statusFilter = 'published'),
                              ),
                              _StatusFilterChip(
                                label: 'Cancelados',
                                selected: _statusFilter == 'cancelled',
                                onTap: () =>
                                    setState(() => _statusFilter = 'cancelled'),
                              ),
                            ],
                          ),
                        ],
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
                          return _LotCard(
                            lot: lot,
                            productName:
                                productNames[lot.productId] ?? 'Producto',
                            busy: _busy,
                            onOpen: () => context.go('/lots/${lot.id}'),
                            onEdit: () => context.go('/lotes/${lot.id}/editar'),
                            onPublish: () => _publish(lot),
                            onCancel: () => _cancel(lot),
                            onDelete: () => _delete(lot),
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

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppTheme.mint,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? AppTheme.primary : AppTheme.outline,
        ),
        labelStyle: TextStyle(
          color: selected ? AppTheme.forest : AppTheme.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      );
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

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.outline),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
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
                          productName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatQuantityMilli(lot.quantityMilli)} ${lot.unit}'
                          ' · $price por ${lot.unit}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: busy ? null : onOpen,
                    child: const Text('Ver'),
                  ),
                  if (lot.status == 'draft') ...[
                    TextButton(
                      onPressed: busy ? null : onEdit,
                      child: const Text('Editar'),
                    ),
                    FilledButton.tonal(
                      onPressed: busy ? null : onPublish,
                      child: const Text('Publicar'),
                    ),
                    IconButton(
                      tooltip: 'Eliminar borrador',
                      onPressed: busy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFB3261E),
                    ),
                  ],
                  if (lot.status == 'published' || lot.status == 'reserved')
                    TextButton(
                      onPressed: busy ? null : onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                      ),
                      child: const Text('Cancelar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
              if (filtered)
                OutlinedButton.icon(
                  onPressed: onClearFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Ver todos'),
                )
              else
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Publicar mi primer lote'),
                ),
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
