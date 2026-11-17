import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/config/catalog_config.dart';
import '../../../core/i18n/formats.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/result/result.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/lot.dart' hide Category, Product;
import '../domain/lot_quantity.dart';
import 'catalog_search_screen.dart' show searchProductsProvider;
import 'providers/catalog_provider.dart';

typedef _S = LotDetailStrings;

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
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    final read = detail.valueOrNull;
    final lot = read?.lot;
    final product = lot == null
        ? null
        : productList?.where((item) => item.id == lot.productId).firstOrNull;
    final carrier = role == 'carrier';
    final seller = role == 'producer' || role == 'supplier';
    final canPop = context.canPop();
    final price = lot == null ? null : AppFormats.moneyText(lot.unitPrice);
    final quantity = lot == null
        ? null
        : LotStrings.quantity(formatQuantityMilli(lot.quantityMilli), lot.unit);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(_S.title),
        leading: IconButton(
          tooltip: canPop
              ? _S.back
              : seller
                  ? _S.backToMyLots
                  : _S.backToSearch,
          icon: const Icon(Icons.arrow_back),
          // Sin historial, quien vende vuelve a sus lotes.
          onPressed: () => canPop
              ? context.pop()
              : context.go(seller ? '/lotes' : '/buscar'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: CatalogConfig.detailMaxWidth),
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
                final location = item.provider == null
                    ? LotStrings.noLocation
                    : LotStrings.location(
                        item.provider!.municipality, item.provider!.department);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (item.photos.isNotEmpty) ...[
                      _PhotoGallery(lot: item),
                      const SizedBox(height: 20),
                    ],
                    if (offline || item.isFromCache)
                      _CachedNotice(updatedAt: item.cachedAt, offline: offline),
                    Text(
                      product?.name ?? LotStrings.productFallback,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.forest,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    if (role == null) const Text(_S.unknownRole),
                    if (price != null && role == 'buyer')
                      Text(LotStrings.pricePer(price, item.unit),
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
                                ? _S.quantityPickup
                                : _S.quantityAvailable,
                            value: quantity ?? CommonStrings.empty),
                        if (role != 'buyer')
                          _DetailRow(
                              icon: Icons.payments_outlined,
                              label: _S.pricePerUnit(item.unit),
                              value: price ?? CommonStrings.empty),
                        _DetailRow(
                            icon: Icons.event_available_outlined,
                            label: _S.availability,
                            value: LotStrings.dateRange(
                                AppFormats.dayMonthYear(item.availableFrom),
                                AppFormats.dayMonthYear(item.availableUntil))),
                        _DetailRow(
                            icon: Icons.place_outlined,
                            label: carrier ? _S.pickupLocation : _S.location,
                            value: location),
                        if (item.qualityGrade?.isNotEmpty == true)
                          _DetailRow(
                              icon: Icons.verified_outlined,
                              label: _S.quality,
                              value: item.qualityGrade!),
                        _DetailRow(
                            icon: Icons.check_circle_outline,
                            label: _S.status,
                            value: seller
                                ? LotStatusStrings.owner(item.status)
                                : LotStatusStrings.public(item.status)),
                      ],
                    ),
                    if (item.provider != null) ...[
                      const SizedBox(height: 16),
                      _DetailSurface(children: [
                        Text(carrier ? _S.originContact : _S.producer,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        _DetailRow(
                            icon: Icons.person_outline,
                            label: _S.provider,
                            value: item.provider!.displayName),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    Text(_S.disclaimer,
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

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.lot});
  final Lot lot;
  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.lot.photos;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 240,
        child: Stack(children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Semantics(
              image: true,
              label: _S.photoLabel(index + 1, photos.length),
              child: Hero(
                tag: index == 0
                    ? 'lot-photo-${widget.lot.id}'
                    : 'lot-photo-${widget.lot.id}-$index',
                child: Image.network(
                  photos[index].url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => const _LotPhotoPlaceholder(),
                ),
              ),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: AppTheme.ink.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(999)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(_S.photoPosition(_page + 1, photos.length),
                        style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppTheme.white,
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
    final prefix = offline ? _S.offline : _S.stale;
    final message = updatedAt == null
        ? '$prefix · ${_S.showingSaved}'
        : '$prefix · ${_S.savedAt(AppFormats.dayMonthTime(updatedAt!))}';
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
      child: CircularProgressIndicator(semanticsLabel: _S.loading));
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
            Text(notFound ? _S.notFound : _S.loadError,
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                  onPressed: onRetry, child: const Text(CommonStrings.retry))
            ]
          ])));
}
