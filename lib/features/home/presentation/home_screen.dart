import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/i18n/strings.dart';
import '../../../shared/widgets/lot_interaction_widgets.dart';
import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/providers/auth_provider.dart'
    show authRepositoryProvider;
import '../../catalog/domain/entities/lot.dart' hide Category, Product;
import '../../catalog/presentation/providers/catalog_provider.dart';
import '../../catalog/presentation/providers/lot_management_provider.dart'
    show catalogProductsProvider;

final homeLotsCacheProvider = StateProvider<List<Lot>?>((ref) => null);

final homeUserProvider = FutureProvider<User?>((ref) async {
  final result = await ref.read(authRepositoryProvider).getStoredUser();
  return result.map(ok: (value) => value.value, err: (_) => null);
});

final homeLotsProvider = FutureProvider<List<Lot>>((ref) async {
  ref.watch(syncRevisionProvider);
  final result = await ref.read(catalogRepositoryProvider).getMyLots();
  return result.map(
    ok: (value) {
      ref.read(homeLotsCacheProvider.notifier).state = value.value;
      return value.value;
    },
    err: (failure) => throw failure,
  );
});

final homeConnectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool isConnected(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  yield isConnected(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isConnected);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(homeUserProvider).valueOrNull;
    if (user?.role == 'carrier') return const _CarrierLanding();
    final lots = ref.watch(homeLotsProvider);
    final cachedLots = ref.watch(homeLotsCacheProvider);
    final products = ref.watch(catalogProductsProvider).valueOrNull ?? const [];
    final Map<String, String> productNames = {
      for (final product in products) product.id: product.name
    };
    final connectivity = ref.watch(homeConnectivityProvider).valueOrNull;
    final items = lots.valueOrNull ?? cachedLots;
    final isSeller = user?.role == 'producer' || user?.role == 'supplier';
    final displayName = user?.fullName.trim().split(RegExp(r'\s+')).firstOrNull;
    final greeting = _greeting(DateTime.now(), displayName);
    final published = items?.where((lot) => lot.status == 'published').length;
    final drafts = items?.where((lot) => lot.status == 'draft').length;

    final action = _primaryAction(
      isSeller: isSeller,
      hasLotsData: items != null,
      published: published ?? 0,
      drafts: drafts ?? 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ColoredBox(
          color: AppTheme.background,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 40 : 20,
                    wide ? 36 : 20,
                    wide ? 40 : 20,
                    wide ? 40 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeBlock(
                        greeting: greeting,
                        isSeller: isSeller,
                        isFirstLot: isSeller &&
                            published == 0 &&
                            drafts == 0 &&
                            items != null,
                        actionLabel: action.label,
                        onAction: () => context.go(action.path),
                      ),
                      if (connectivity == false) ...[
                        const SizedBox(height: 20),
                        const _OfflineNotice(),
                      ],
                      if (lots.hasError && connectivity != false) ...[
                        const SizedBox(height: 20),
                        _LoadErrorNotice(
                          onRetry: () => ref.invalidate(homeLotsProvider),
                        ),
                      ],
                      if (isSeller) ...[
                        const SizedBox(height: 32),
                        _SellerActivity(
                          lots: items,
                          loading: lots.isLoading && items == null,
                          onPublishedTap: () =>
                              context.go('/lotes?status=published'),
                          onDraftsTap: () => context.go('/lotes?status=draft'),
                          productNames: productNames,
                          onLotTap: (id) => context.go('/lots/$id'),
                        ),
                      ] else if (items != null) ...[
                        const SizedBox(height: 32),
                        _RecentLotActivity(
                            lots: items,
                            productNames: productNames,
                            onLotTap: (id) => context.go('/lots/$id'),
                            onViewAll: () => context.go('/buscar')),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CarrierLanding extends StatelessWidget {
  const _CarrierLanding();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppTheme.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 52, color: AppTheme.carrierAccent),
                  const SizedBox(height: 20),
                  Text(LogisticsStrings.homeHeadline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    LogisticsStrings.homeDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/logistica'),
                    icon: const Icon(Icons.route_outlined),
                    label: const Text(LogisticsStrings.openLogistics),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

({String label, String path}) _primaryAction({
  required bool isSeller,
  required bool hasLotsData,
  required int published,
  required int drafts,
}) {
  if (!isSeller) return (label: 'Buscar lotes', path: '/buscar');
  if (!hasLotsData) {
    return (label: 'Publicar lote', path: '/lotes?intent=create');
  }
  if (published == 0 && drafts == 0) {
    return (label: 'Publicar mi primer lote', path: '/lotes?intent=create');
  }
  if (published == 0 && drafts > 0) {
    return (label: 'Ver mis borradores', path: '/lotes?status=draft');
  }
  return (label: 'Publicar otro lote', path: '/lotes?intent=create');
}

String _greeting(DateTime now, String? firstName) {
  final salutation = now.hour >= 5 && now.hour < 12
      ? 'Buenos días'
      : now.hour >= 12 && now.hour < 19
          ? 'Buenas tardes'
          : 'Buenas noches';
  if (firstName == null || firstName.isEmpty) return '$salutation.';
  return '$salutation, $firstName.';
}

class _WelcomeBlock extends StatelessWidget {
  const _WelcomeBlock({
    required this.greeting,
    required this.isSeller,
    required this.isFirstLot,
    required this.actionLabel,
    required this.onAction,
  });

  final String greeting;
  final bool isSeller;
  final bool isFirstLot;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isSeller
                ? isFirstLot
                    ? 'Lleva tu cosecha al mercado.'
                    : 'Tu oferta, más cerca de nuevos compradores.'
                : 'Encuentra productos directo del campo.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.forest,
                  fontSize: 28,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isSeller
                ? 'Publica y mantén al día tus lotes desde aquí.'
                : 'Compara lotes disponibles para abastecer tu negocio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: .78),
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: Icon(isSeller ? Icons.add_rounded : Icons.search_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      );
}

class _SellerActivity extends StatelessWidget {
  const _SellerActivity({
    required this.lots,
    required this.loading,
    required this.onPublishedTap,
    required this.onDraftsTap,
    required this.productNames,
    required this.onLotTap,
  });

  final List<Lot>? lots;
  final bool loading;
  final VoidCallback onPublishedTap;
  final VoidCallback onDraftsTap;
  final Map<String, String> productNames;
  final ValueChanged<String> onLotTap;

  @override
  Widget build(BuildContext context) {
    final published = lots?.where((lot) => lot.status == 'published').length;
    final drafts = lots?.where((lot) => lot.status == 'draft').length;
    final recent = List<Lot>.of(lots ?? const <Lot>[])
      ..sort((a, b) => b.availableFrom.compareTo(a.availableFrom));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu actividad',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MetricAction(
                  label: 'Publicados',
                  value: loading ? null : '${published ?? 0}',
                  onTap: onPublishedTap,
                  semanticLabel: 'Ver lotes publicados, ${published ?? 0}',
                ),
              ),
              const SizedBox(height: 64, child: VerticalDivider(width: 1)),
              Expanded(
                child: _MetricAction(
                  label: 'Borradores',
                  value: loading ? null : '${drafts ?? 0}',
                  onTap: onDraftsTap,
                  semanticLabel: 'Ver mis borradores, ${drafts ?? 0}',
                ),
              ),
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Actividad reciente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          for (var index = 0; index < recent.take(5).length; index++)
            _RecentLotActivityItem(
                lot: recent[index],
                productName: productNames[recent[index].productId] ??
                    'Producto agropecuario',
                index: index,
                onTap: () => onLotTap(recent[index].id)),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: () => context.go('/lotes'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Ver todo'))),
        ] else if (!loading && lots != null) ...[
          const SizedBox(height: 16),
          Text(
            'Aún no tienes lotes. Tu actividad aparecerá aquí cuando publiques el primero.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: .76),
                  fontSize: 14,
                ),
          ),
        ],
      ],
    );
  }
}

class _MetricAction extends StatelessWidget {
  const _MetricAction({
    required this.label,
    required this.value,
    required this.onTap,
    required this.semanticLabel,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  value == null
                      ? Text('—',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  color: AppTheme.forest,
                                  fontSize: 27,
                                  height: 1.1))
                      : AnimatedCounter(
                          value: int.tryParse(value!) ?? 0,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  color: AppTheme.forest,
                                  fontSize: 27,
                                  height: 1.1)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: .78),
                            fontSize: 14,
                          )),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RecentLotActivity extends StatelessWidget {
  const _RecentLotActivity(
      {required this.lots,
      required this.productNames,
      required this.onLotTap,
      required this.onViewAll});
  final List<Lot> lots;
  final Map<String, String> productNames;
  final ValueChanged<String> onLotTap;
  final VoidCallback onViewAll;
  @override
  Widget build(BuildContext context) {
    final recent = List<Lot>.of(lots)
      ..sort((a, b) => b.availableFrom.compareTo(a.availableFrom));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Actividad reciente',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppTheme.ink, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (recent.isEmpty)
        const Card(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'Aún no hay actividad. Cuando tengas lotes o pedidos, aparecerán aquí.')))
      else ...[
        for (var i = 0; i < recent.take(5).length; i++)
          _RecentLotActivityItem(
              lot: recent[i],
              productName:
                  productNames[recent[i].productId] ?? 'Producto agropecuario',
              index: i,
              onTap: () => onLotTap(recent[i].id)),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver todo'))),
      ],
    ]);
  }
}

class _RecentLotActivityItem extends StatelessWidget {
  const _RecentLotActivityItem(
      {required this.lot,
      required this.productName,
      required this.index,
      required this.onTap});
  final Lot lot;
  final String productName;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDraft = lot.status == 'draft';
    final isCancelled = lot.status == 'cancelled';
    final action = isDraft
        ? 'Guardaste borrador'
        : isCancelled
            ? 'Cancelaste'
            : lot.status == 'published'
                ? 'Publicaste'
                : 'Estado del lote';
    final amount = (int.tryParse(lot.quantityMilli) ?? 0) / 1000;
    final price =
        NumberFormat.currency(locale: 'es_CO', symbol: r'$ ', decimalDigits: 0)
            .format(int.tryParse(lot.unitPrice) ?? 0);
    final elapsed = DateTime.now().difference(lot.availableFrom.toLocal());
    final time = elapsed.isNegative
        ? 'Disponible en ${elapsed.inDays.abs()} d'
        : elapsed.inDays >= 1
            ? 'Disponible desde hace ${elapsed.inDays} d'
            : elapsed.inHours >= 1
                ? 'Disponible desde hace ${elapsed.inHours} h'
                : 'Disponible desde hoy';
    return ActivityTimelineItem(
      index: index,
      title: productName,
      description: action,
      metadata: '$amount ${lot.unit} · $price/${lot.unit}',
      timeLabel: time,
      icon: isDraft
          ? Icons.edit_note_rounded
          : isCancelled
              ? Icons.cancel_outlined
              : Icons.check_circle_outline_rounded,
      color: isDraft
          ? AppTheme.earth
          : isCancelled
              ? const Color(0xFFC75B58)
              : AppTheme.primary,
      thumbnail: LotThumbnail(
          url: lot.photos.firstOrNull?.url,
          heroTag: 'lot-photo-${lot.id}',
          size: 56),
      onTap: onTap,
    );
  }
}

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
                'Sin conexión. Mostramos la información guardada.',
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

class _LoadErrorNotice extends StatelessWidget {
  const _LoadErrorNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync_problem_outlined,
                color: Color(0xFF704E00), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No pudimos actualizar tus lotes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF553B00),
                      fontSize: 14,
                    ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
}
