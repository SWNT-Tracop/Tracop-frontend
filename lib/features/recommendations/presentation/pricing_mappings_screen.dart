import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../backoffice/presentation/backoffice_provider.dart';
import 'recommendations_provider.dart';

class PricingMappingsScreen extends ConsumerWidget {
  const PricingMappingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Asociaciones de precios')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
                'Confirma qué presentación de DANE-SIPSA corresponde a cada producto. No se hacen conversiones automáticas.'),
            const SizedBox(height: 16),
            ref.watch(pricingMappingsProvider).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(_errorText(error)),
                  data: (items) => Column(children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _create(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva asociación'),
                      ),
                    ),
                    for (final raw in items) _MappingTile(item: _map(raw)),
                    if (items.isEmpty)
                      const Card(
                          child: ListTile(
                              title:
                                  Text('No hay asociaciones configuradas.'))),
                  ]),
                ),
          ],
        ),
      );

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final products = ref.read(backofficeProductsProvider).valueOrNull ?? [];
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Primero debe existir un producto en el catálogo.')));
      return;
    }
    final draft = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => _MappingForm(products: products));
    if (draft == null || !context.mounted) return;
    final repository = ref.read(recommendationsRepositoryProvider);
    final result =
        await repository.guard(() => repository.remote.createMapping({
              'id': const Uuid().v7(),
              ...draft,
            }));
    if (!context.mounted) return;
    result.map(
      ok: (_) {
        ref.invalidate(pricingMappingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asociación creada correctamente.')));
      },
      err: (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.error.message))),
    );
  }
}

class _MappingTile extends StatelessWidget {
  const _MappingTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title:
              Text(item['sourceProduct']?.toString() ?? 'Sin producto fuente'),
          subtitle: Text(
              '${item['unit'] ?? '-'} · ${item['presentation'] ?? '-'} · ${item['source'] ?? 'DANE-SIPSA'}'),
          trailing: IconButton(
            tooltip: 'Eliminar asociación',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                        title: const Text('Eliminar asociación'),
                        content: const Text('Esta acción quedará auditada.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(dialogContext,
                                      rootNavigator: true)
                                  .pop(false),
                              child: const Text('Cancelar')),
                          FilledButton(
                              onPressed: () => Navigator.of(dialogContext,
                                      rootNavigator: true)
                                  .pop(true),
                              child: const Text('Eliminar')),
                        ],
                      ));
              if (confirmed != true || !context.mounted) return;
              final id = item['id']?.toString();
              if (id == null) return;
              final container = ProviderScope.containerOf(context);
              final result = await container
                  .read(recommendationsRepositoryProvider)
                  .guard(() => container
                      .read(recommendationsRepositoryProvider)
                      .remote
                      .deleteMapping(id));
              if (!context.mounted) return;
              result.map(
                ok: (_) => container.invalidate(pricingMappingsProvider),
                err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.error.message))),
              );
            },
          ),
        ),
      );
}

class _MappingForm extends StatefulWidget {
  const _MappingForm({required this.products});
  final List<dynamic> products;

  @override
  State<_MappingForm> createState() => _MappingFormState();
}

class _MappingFormState extends State<_MappingForm> {
  final sourceProduct = TextEditingController();
  final presentation = TextEditingController();
  String? productId;

  @override
  void dispose() {
    sourceProduct.dispose();
    presentation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products.map(_map).toList();
    productId ??= products.first['id']?.toString();
    final product = products.firstWhere((item) => item['id'] == productId,
        orElse: () => <String, dynamic>{});
    return AlertDialog(
      title: const Text('Nueva asociación'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          initialValue: productId,
          decoration: const InputDecoration(labelText: 'Producto TRACOP'),
          items: [
            for (final item in products)
              DropdownMenuItem(
                  value: item['id']?.toString(),
                  child: Text(item['name']?.toString() ?? 'Producto')),
          ],
          onChanged: (value) => setState(() => productId = value),
        ),
        TextField(
            controller: sourceProduct,
            decoration:
                const InputDecoration(labelText: 'Producto DANE-SIPSA')),
        TextField(
            controller: presentation,
            decoration: const InputDecoration(labelText: 'Presentación')),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Unidad: ${product['unit'] ?? '-'}')),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final source = sourceProduct.text.trim();
            final shownAs = presentation.text.trim();
            if (productId == null || source.isEmpty || shownAs.isEmpty) return;
            Navigator.of(context, rootNavigator: true).pop({
              'productId': productId,
              'unit': product['unit'],
              'source': 'DANE-SIPSA',
              'sourceProduct': source,
              'presentation': shownAs,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

String _errorText(Object error) => error.toString();

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
