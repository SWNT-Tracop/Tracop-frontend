import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../catalog/domain/entities/lot.dart' hide Category, Product;
import '../../catalog/presentation/providers/catalog_provider.dart';

final homeLotsCacheProvider = StateProvider<List<Lot>?>((ref) => null);

final homeUserProvider = FutureProvider<User?>((ref) async {
  final result = await ref.read(authRepositoryProvider).getStoredUser();
  return result.map(ok: (value) => value.value, err: (_) => null);
});

final homeLotsProvider = FutureProvider<List<Lot>>((ref) async {
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
    final lots = ref.watch(homeLotsProvider);
    final cachedLots = ref.watch(homeLotsCacheProvider);
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
                        ),
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
  });

  final List<Lot>? lots;
  final bool loading;
  final VoidCallback onPublishedTap;
  final VoidCallback onDraftsTap;

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
          for (final lot in recent.take(2)) _RecentLotLine(lot: lot),
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
                  Text(value ?? '—',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.forest,
                                fontSize: 27,
                                height: 1.1,
                              )),
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

class _RecentLotLine extends StatelessWidget {
  const _RecentLotLine({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (lot.status) {
      'published' => 'Publicado',
      'draft' => 'Borrador',
      'reserved' => 'Reservado',
      'sold_out' => 'Agotado',
      'cancelled' => 'Cancelado',
      'expired' => 'Vencido',
      _ => 'En preparación',
    };
    final date = '${lot.availableFrom.day.toString().padLeft(2, '0')}/'
        '${lot.availableFrom.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: _statusColor(lot.status)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$statusLabel · disponible desde $date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink.withValues(alpha: .82),
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
      'published' => AppTheme.primary,
      'draft' => AppTheme.earth,
      'reserved' => const Color(0xFF1565C0),
      'sold_out' || 'cancelled' || 'expired' => AppTheme.mutedText,
      _ => AppTheme.mutedText,
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
