import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/formats.dart';
import '../../../core/result/result.dart';
import '../../catalog/presentation/providers/catalog_provider.dart';
import 'recommendations_provider.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Recomendaciones y precios')),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recommendedLotsProvider);
            ref.invalidate(priceAlertsProvider);
            await ref.read(recommendedLotsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Lotes para ti',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _RecommendationsBody(ref: ref),
              const SizedBox(height: 24),
              _AlertsSection(ref: ref),
            ],
          ),
        ),
      );
}

class _RecommendationsBody extends StatelessWidget {
  const _RecommendationsBody({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => ref.watch(recommendedLotsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RecommendationError(error: error),
        data: (page) {
          final items = page['items'] as List? ?? const [];
          if (items.isEmpty) {
            return const Card(
                child: ListTile(
                    title: Text('Aún no hay recomendaciones'),
                    subtitle: Text(
                        'Compra o explora lotes para recibir sugerencias más útiles.')));
          }
          return Column(children: [
            for (final raw in items) _RecommendedLotCard(item: _map(raw)),
            if (page['nextCursor'] != null)
              TextButton(
                  onPressed: () => ref.invalidate(recommendedLotsProvider),
                  child: const Text('Actualizar recomendaciones')),
          ]);
        },
      );
}

class _RecommendedLotCard extends StatelessWidget {
  const _RecommendedLotCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final reasons = (item['reasons'] as List?)?.map(_reasonLabel).join(' · ');
    final price = int.tryParse(item['unitPrice']?.toString() ?? '');
    return Card(
      child: ListTile(
        title: const Text('Producto recomendado'),
        subtitle: Text([
          if (price != null)
            '${AppFormats.moneyText(price.toString())}/${item['unit'] ?? ''}',
          if (item['distanceKm'] != null) '${item['distanceKm']} km',
          if (reasons != null && reasons.isNotEmpty) reasons,
        ].join(' · ')),
        trailing: IconButton(
          tooltip: 'Ver lote',
          icon: const Icon(Icons.open_in_new),
          onPressed: () {
            final id = item['lotId']?.toString();
            if (id != null && id.isNotEmpty) context.push('/lotes/$id');
          },
        ),
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(priceAlertsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(
            child: Text('Alertas de precio',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        FilledButton.icon(
          onPressed: () => _openAlertForm(context, ref),
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Nueva alerta'),
        ),
      ]),
      const SizedBox(height: 8),
      alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RecommendationError(error: error),
        data: (items) => items.isEmpty
            ? const Card(
                child: ListTile(
                    title: Text('No tienes alertas activas'),
                    subtitle: Text(
                        'Te avisaremos cuando aparezca un lote bajo tu precio.')))
            : Column(children: [
                for (final raw in items) _AlertTile(item: _map(raw))
              ]),
      ),
    ]);
  }

  Future<void> _openAlertForm(BuildContext context, WidgetRef ref) async {
    var products = ref.read(catalogProvider.notifier).products;
    if (products.isEmpty) {
      await ref.read(catalogProvider.notifier).loadProducts();
      products = ref.read(catalogProvider.notifier).products;
    }
    if (!context.mounted) return;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('No hay productos disponibles para crear una alerta.')));
      return;
    }
    final draft = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AlertForm(products: products),
    );
    if (draft == null || !context.mounted) return;
    final result = await ref.read(recommendationsRepositoryProvider).guard(
          () => ref.read(recommendationsRepositoryProvider).remote.createAlert({
            'id': const Uuid().v7(),
            ...draft,
          }),
        );
    if (!context.mounted) return;
    result.map(
      ok: (_) {
        ref.invalidate(priceAlertsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alerta creada correctamente.')));
      },
      err: (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.error.message))),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(
              'Hasta ${AppFormats.moneyText((int.tryParse(item['maxPrice']?.toString() ?? '') ?? 0).toString())}'),
          subtitle: Text(
              'Radio: ${item['radiusKm'] ?? '-'} km · Centro: ${item['centerLat'] ?? '-'}, ${item['centerLng'] ?? '-'}'),
          trailing: IconButton(
            tooltip: 'Eliminar alerta',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (!await _confirm(context)) return;
              if (!context.mounted) return;
              final id = item['id']?.toString();
              if (id == null) return;
              final container = ProviderScope.containerOf(context);
              final result = await container
                  .read(recommendationsRepositoryProvider)
                  .guard(() => container
                      .read(recommendationsRepositoryProvider)
                      .remote
                      .deleteAlert(id));
              if (!context.mounted) return;
              result.map(
                ok: (_) => container.invalidate(priceAlertsProvider),
                err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.error.toString()))),
              );
            },
          ),
        ),
      );
}

class _AlertForm extends StatefulWidget {
  const _AlertForm({required this.products});
  final List<dynamic> products;

  @override
  State<_AlertForm> createState() => _AlertFormState();
}

class _AlertFormState extends State<_AlertForm> {
  final maxPrice = TextEditingController();
  final radius = TextEditingController(text: '50');
  final lat = TextEditingController();
  final lng = TextEditingController();
  String? productId;

  @override
  void dispose() {
    maxPrice.dispose();
    radius.dispose();
    lat.dispose();
    lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products.map(_map).toList();
    productId ??= products.first['id']?.toString();
    return AlertDialog(
      title: const Text('Nueva alerta de precio'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: productId,
            decoration: const InputDecoration(labelText: 'Producto'),
            items: [
              for (final product in products)
                DropdownMenuItem(
                    value: product['id']?.toString(),
                    child: Text(product['name']?.toString() ?? 'Producto')),
            ],
            onChanged: (value) => setState(() => productId = value),
          ),
          TextField(
              controller: maxPrice,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Precio máximo COP')),
          TextField(
              controller: radius,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Radio en km')),
          TextField(
              controller: lat,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitud')),
          TextField(
              controller: lng,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitud')),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final price = int.tryParse(maxPrice.text.trim());
            final radiusKm = int.tryParse(radius.text.trim());
            final latitude = double.tryParse(lat.text.trim());
            final longitude = double.tryParse(lng.text.trim());
            if (productId == null ||
                price == null ||
                price <= 0 ||
                radiusKm == null ||
                radiusKm <= 0 ||
                latitude == null ||
                longitude == null) {
              return;
            }
            Navigator.of(context, rootNavigator: true).pop({
              'productId': productId,
              'maxPrice': price,
              'radiusKm': radiusKm,
              'lat': latitude,
              'lng': longitude,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _RecommendationError extends StatelessWidget {
  const _RecommendationError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final failure = error is DomainFailure ? error as DomainFailure : null;
    return Text(failure?.message ?? 'No se pudo cargar esta sección.');
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

String _reasonLabel(Object? reason) => switch (reason?.toString()) {
      'reorder' => 'Lo has comprado antes',
      'nearby' => 'Cerca de ti',
      'good_price' => 'Buen precio',
      'verified_provider' => 'Proveedor verificado',
      'fresh' => 'Oferta reciente',
      _ => 'Recomendado',
    };

Future<bool> _confirm(BuildContext context) async =>
    await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Eliminar alerta'),
              content:
                  const Text('Dejarás de recibir avisos para este producto.'),
              actions: [
                TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(true),
                    child: const Text('Eliminar')),
              ],
            )) ??
    false;
