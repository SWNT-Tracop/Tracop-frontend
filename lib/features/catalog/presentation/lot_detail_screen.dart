import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/result/result.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/lot.dart' hide Category, Product;
import 'catalog_search_screen.dart' show searchProductsProvider;
import 'providers/catalog_provider.dart';

final lotDetailProvider =
    FutureProvider.family<LotRead, String>((ref, id) async {
  final result = await ref.read(catalogRepositoryProvider).getLot(id);
  return result.map(
    ok: (value) => LotRead(lot: value.value),
    err: (failure) => LotRead(failure: failure.error),
  );
});

class LotRead {
  const LotRead({this.lot, this.failure});
  final Lot? lot;
  final DomainFailure? failure;
}

class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({required this.lotId, super.key});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(homeConnectivityProvider, (previous, next) {
      if (previous?.valueOrNull == false && next.valueOrNull == true) {
        ref.invalidate(lotDetailProvider(lotId));
      }
    });
    final detail = ref.watch(lotDetailProvider(lotId));
    final role = ref.watch(homeUserProvider).valueOrNull?.role ??
        ref.watch(authProvider).valueOrNull?.user.role;
    final productList = ref.watch(searchProductsProvider).valueOrNull;
    final read = detail.valueOrNull;
    final lot = read?.lot;
    final product = lot == null
        ? null
        : productList?.where((item) => item.id == lot.productId).firstOrNull;
    final carrier = role == 'carrier';
    final price = lot == null
        ? null
        : NumberFormat.currency(
                locale: 'es_CO', symbol: r'$ ', decimalDigits: 0)
            .format(int.tryParse(lot.unitPrice) ?? 0);
    final quantity = lot == null
        ? null
        : '${(int.tryParse(lot.quantityMilli) ?? 0) / 1000} ${lot.unit}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Detalle del lote'),
        leading: IconButton(
          tooltip: 'Volver a resultados',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/buscar'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: detail.when(
              loading: () => const _DetailLoading(),
              error: (_, __) => _DetailError(
                  onRetry: () => ref.invalidate(lotDetailProvider(lotId))),
              data: (result) {
                if (result.lot == null) {
                  final notFound = result.failure?.statusCode == 404;
                  return _DetailError(
                    notFound: notFound,
                    onRetry: notFound
                        ? null
                        : () => ref.invalidate(lotDetailProvider(lotId)),
                  );
                }
                final item = result.lot!;
                final itemProduct = product;
                final location = item.provider == null
                    ? 'Ubicación no informada'
                    : '${item.provider!.municipality}, ${item.provider!.department}';
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (item.photos.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          height: 240,
                          child: PageView.builder(
                            itemCount: item.photos.length,
                            itemBuilder: (context, index) => Image.network(
                              item.photos[index].url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _LotPhotoPlaceholder(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (ref.watch(homeConnectivityProvider).valueOrNull ==
                            false ||
                        item.isFromCache)
                      _CachedNotice(
                        updatedAt: item.cachedAt,
                        offline:
                            ref.watch(homeConnectivityProvider).valueOrNull ==
                                false,
                      ),
                    Text(
                      itemProduct?.name ?? 'Producto agropecuario',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.forest,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    if (role == null)
                      const Text(
                          'No pudimos confirmar tu rol; ocultamos acciones específicas.'),
                    if (price != null && role == 'buyer')
                      Text(price,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: AppTheme.forest,
                                  fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
                    _DetailSurface(
                      children: [
                        _DetailRow(
                            icon: Icons.inventory_2_outlined,
                            label: carrier
                                ? 'Cantidad para recoger'
                                : 'Cantidad disponible',
                            value: quantity ?? '—'),
                        if (role != 'buyer')
                          _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Precio por ${item.unit}',
                              value: price ?? '—'),
                        _DetailRow(
                            icon: Icons.event_available_outlined,
                            label: 'Disponibilidad',
                            value:
                                '${DateFormat('d MMM y', 'es_CO').format(item.availableFrom.toLocal())} – ${DateFormat('d MMM y', 'es_CO').format(item.availableUntil.toLocal())}'),
                        _DetailRow(
                            icon: Icons.place_outlined,
                            label:
                                carrier ? 'Ubicación de recogida' : 'Ubicación',
                            value: location),
                        if (item.qualityGrade?.isNotEmpty == true)
                          _DetailRow(
                              icon: Icons.verified_outlined,
                              label: 'Calidad informada',
                              value: item.qualityGrade!),
                        _DetailRow(
                            icon: Icons.check_circle_outline,
                            label: 'Estado',
                            value: _statusText(item.status)),
                      ],
                    ),
                    if (item.provider != null) ...[
                      const SizedBox(height: 16),
                      _DetailSurface(children: [
                        Text(carrier ? 'Contacto de origen' : 'Productor',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Proveedor',
                            value: item.provider!.displayName),
                        _DetailRow(
                            icon: Icons.location_city_outlined,
                            label: 'Municipio',
                            value: location),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    Text(
                        'La disponibilidad puede cambiar. La información se confirma con el proveedor.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.mutedText)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _statusText(String status) => switch (status) {
      'published' => 'Disponible',
      'reserved' => 'Reservado',
      'sold_out' => 'Agotado',
      'expired' => 'Vencido',
      'cancelled' => 'Cancelado',
      _ => status,
    };

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          SizedBox(
              width: 142,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.mutedText))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

class _CachedNotice extends StatelessWidget {
  const _CachedNotice({required this.updatedAt, required this.offline});
  final DateTime? updatedAt;
  final bool offline;
  @override
  Widget build(BuildContext context) {
    final prefix = offline ? 'Sin conexión' : 'No se pudo actualizar';
    final message = updatedAt == null
        ? '$prefix · mostrando detalle guardado'
        : '$prefix · guardado ${DateFormat('d MMM, HH:mm', 'es_CO').format(updatedAt!.toLocal())}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
      ),
    );
  }
}

class _LotPhotoPlaceholder extends StatelessWidget {
  const _LotPhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.mint.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 36, color: AppTheme.forest),
      );
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();
  @override
  Widget build(BuildContext context) => const Center(
      child: CircularProgressIndicator(
          semanticsLabel: 'Cargando detalle del lote'));
}

class _DetailError extends StatelessWidget {
  const _DetailError({this.notFound = false, this.onRetry});
  final bool notFound;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(notFound ? Icons.search_off : Icons.wifi_off_outlined,
                size: 42, color: AppTheme.mutedText),
            const SizedBox(height: 12),
            Text(
                notFound
                    ? 'Este lote ya no está disponible.'
                    : 'No pudimos cargar el detalle del lote.',
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                  onPressed: onRetry, child: const Text('Reintentar'))
            ]
          ])));
}
