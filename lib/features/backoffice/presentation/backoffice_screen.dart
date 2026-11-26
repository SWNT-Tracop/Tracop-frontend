import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/result/result.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/backoffice_remote.dart';
import 'backoffice_provider.dart';

enum BackofficeSection {
  dashboard,
  verifications,
  proposals,
  catalog,
  logistics,
  parameters,
  audit
}

class BackofficeScreen extends ConsumerWidget {
  const BackofficeScreen({required this.section, super.key});

  final BackofficeSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (section) {
      BackofficeSection.dashboard => const _DashboardView(),
      BackofficeSection.verifications => const _VerificationsView(),
      BackofficeSection.proposals => const _ProposalsView(),
      BackofficeSection.catalog => const _CatalogView(),
      BackofficeSection.logistics => const _LogisticsView(),
      BackofficeSection.parameters => const _ParametersView(),
      BackofficeSection.audit => const _AuditView(),
    };
  }
}

class _BackofficePage extends StatelessWidget {
  const _BackofficePage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(20), children: [child]),
      );
}

class _AsyncBody extends StatelessWidget {
  const _AsyncBody({required this.state, required this.builder});
  final AsyncValue<dynamic> state;
  final Widget Function(dynamic value) builder;

  @override
  Widget build(BuildContext context) => state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorCard(message: _friendlyError(error)),
        data: builder,
      );
}

String _friendlyError(Object error) => error is DomainFailure
    ? error.message
    : 'No se pudo cargar esta sección. Verifica la conexión e inténtalo de nuevo.';

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message),
        ),
      );
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BackofficePage(
        title: 'Resumen operativo',
        child: _AsyncBody(
          state: ref.watch(backofficeMetricsProvider),
          builder: (value) {
            final metrics = Map<String, dynamic>.from(value as Map);
            final payments = _map(metrics['payments']);
            final notifications = _map(metrics['notificationDeliveries']);
            final outbox = _map(metrics['outbox']);
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actualizado: ${metrics['generatedAt'] ?? 'ahora'}'),
                  const SizedBox(height: 16),
                  _MetricGrid(items: [
                    (
                      'Pedidos pagados',
                      metrics['paidOrdersTotalCop'],
                      Icons.payments_outlined
                    ),
                    (
                      'Comprobantes por revisar',
                      payments['proofsAwaitingReview'],
                      Icons.fact_check_outlined
                    ),
                    (
                      'Disputas abiertas',
                      payments['openDisputes'],
                      Icons.warning_amber_outlined
                    ),
                    (
                      'Lotes publicados',
                      _map(metrics['lotsByStatus'])['published'],
                      Icons.inventory_2_outlined
                    ),
                    (
                      'Notificaciones fallidas',
                      notifications['failed'],
                      Icons.notifications_off_outlined
                    ),
                    (
                      'Outbox pendientes',
                      outbox['pending'],
                      Icons.sync_problem_outlined
                    ),
                  ]),
                ]);
          },
        ),
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});
  final List<(String, Object?, IconData)> items;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 500
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            for (final item in items)
              Card(
                  child: ListTile(
                      leading: Icon(item.$3),
                      title: Text(item.$1),
                      subtitle: Text('${item.$2 ?? 0}')))
          ],
        );
      });
}

class _VerificationsView extends ConsumerWidget {
  const _VerificationsView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BackofficePage(
        title: 'Verificaciones de proveedores',
        child: _AsyncBody(
          state: ref.watch(backofficeVerificationsProvider),
          builder: (value) => Column(children: [
            for (final raw in value as List)
              _VerificationTile(
                  item: _map(raw),
                  onChanged: () =>
                      ref.invalidate(backofficeVerificationsProvider)),
            if (value.isEmpty)
              const _EmptyCard(message: 'No hay solicitudes de verificación.'),
          ]),
        ),
      );
}

class _VerificationTile extends ConsumerWidget {
  const _VerificationTile({required this.item, required this.onChanged});
  final Map<String, dynamic> item;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: ListTile(
          title:
              Text('Proveedor ${item['providerId'] ?? item['id'] ?? 'sin ID'}'),
          subtitle: Text(
              'Estado: ${item['status'] ?? 'pendiente'}\n${item['note'] ?? ''}'),
          isThreeLine: true,
          trailing: Wrap(spacing: 4, children: [
            IconButton(
              tooltip: 'Ver reputación',
              onPressed: () => _showSubject(context, ref),
              icon: const Icon(Icons.person_search_outlined),
            ),
            OutlinedButton(
                onPressed: () => _approve(context, ref),
                child: const Text('Aprobar')),
            TextButton(
                onPressed: () => _reason(context, ref, false),
                child: const Text('Rechazar')),
            if (item['status'] == 'verified')
              TextButton(
                  onPressed: () => _reason(context, ref, true),
                  child: const Text('Revocar')),
          ]),
        ),
      );

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(context, 'Aprobar verificación',
        'Confirma las tres comprobaciones obligatorias.');
    if (!confirmed || !context.mounted) return;
    final id = item['providerId']?.toString();
    if (id == null) return;
    final repository = ref.read(backofficeRepositoryProvider);
    await repository.remote.approveVerification(id, const {
      'contact_confirmed': true,
      'location_confirmed': true,
      'reference_checked': true,
    });
    onChanged();
  }

  Future<void> _reason(BuildContext context, WidgetRef ref, bool revoke) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(
                  revoke ? 'Revocar verificación' : 'Rechazar verificación'),
              content: TextField(
                  controller: controller,
                  maxLength: 300,
                  decoration: const InputDecoration(labelText: 'Motivo')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    child: const Text('Confirmar'))
              ],
            ));
    if (reason == null || reason.isEmpty || !context.mounted) return;
    final id = item['providerId']?.toString();
    if (id == null) return;
    final remote = ref.read(backofficeRepositoryProvider).remote;
    if (revoke) {
      await remote.revokeVerification(id, reason);
    } else {
      await remote.rejectVerification(id, reason);
    }
    onChanged();
  }

  Future<void> _showSubject(BuildContext context, WidgetRef ref) async {
    final id = item['providerId']?.toString();
    if (id == null) return;
    final subject =
        await ref.read(backofficeRepositoryProvider).remote.subject(id);
    if (!context.mounted) return;
    final reputation = _map(subject['reputation']);
    final ratings = subject['ratings'] as List? ?? const [];
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reputación del proveedor'),
        content: SizedBox(
          width: 480,
          child: ListView(shrinkWrap: true, children: [
            Text(
                'Promedio: ${reputation['average'] ?? reputation['ratingAverage'] ?? '-'}'),
            Text('Calificaciones: ${reputation['ratingsCount'] ?? '-'}'),
            const SizedBox(height: 12),
            for (final raw in ratings)
              ListTile(
                dense: true,
                title: Text('Puntuación: ${_map(raw)['score'] ?? '-'}'),
                subtitle:
                    Text(_map(raw)['comment']?.toString() ?? 'Sin comentario'),
                trailing: _map(raw)['hidden'] == true
                    ? const Text('Oculto')
                    : IconButton(
                        tooltip: 'Ocultar comentario',
                        icon: const Icon(Icons.visibility_off_outlined),
                        onPressed: () async {
                          final ratingId = _map(raw)['id']?.toString();
                          if (ratingId == null) {
                            return;
                          }
                          if (!await _confirm(context, 'Ocultar comentario',
                              'La puntuación seguirá contando.')) {
                            return;
                          }
                          await ref
                              .read(backofficeRepositoryProvider)
                              .remote
                              .hideRating(ratingId);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
              ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

Future<bool> _confirm(
        BuildContext context, String title, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (_) =>
            AlertDialog(title: Text(title), content: Text(message), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar'))
            ])) ??
    false;

class _ProposalsView extends ConsumerWidget {
  const _ProposalsView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BackofficePage(
        title: 'Propuestas de producto',
        child: _AsyncBody(
            state: ref.watch(backofficeProposalsProvider),
            builder: (value) => Column(children: [
                  for (final raw in value as List)
                    _ProposalTile(
                        item: _map(raw),
                        onChanged: () =>
                            ref.invalidate(backofficeProposalsProvider)),
                  if (value.isEmpty)
                    const _EmptyCard(message: 'No hay propuestas pendientes.')
                ])),
      );
}

class _ProposalTile extends ConsumerWidget {
  const _ProposalTile({required this.item, required this.onChanged});
  final Map<String, dynamic> item;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
      child: ListTile(
          title: Text(item['name']?.toString() ??
              item['productName']?.toString() ??
              'Producto sin nombre'),
          subtitle: Text('Estado: ${item['status'] ?? 'pendiente'}'),
          trailing: Wrap(children: [
            IconButton(
                tooltip: 'Aprobar',
                onPressed: () async {
                  if (await _confirm(context, 'Aprobar propuesta',
                      'La propuesta quedará disponible en el catálogo.')) {
                    await ref
                        .read(backofficeRepositoryProvider)
                        .remote
                        .approveProposal(item['id'].toString());
                    onChanged();
                  }
                },
                icon: const Icon(Icons.check)),
            IconButton(
                tooltip: 'Rechazar',
                onPressed: () async {
                  final reason = await _textReason(context);
                  if (reason != null) {
                    await ref
                        .read(backofficeRepositoryProvider)
                        .remote
                        .rejectProposal(item['id'].toString(), reason);
                    onChanged();
                  }
                },
                icon: const Icon(Icons.close))
          ])));
}

class _CatalogView extends ConsumerStatefulWidget {
  const _CatalogView();

  @override
  ConsumerState<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<_CatalogView> {
  bool products = true;

  @override
  Widget build(BuildContext context) => _BackofficePage(
        title: 'Catálogo curado',
        child: Column(children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Productos')),
              ButtonSegment(value: false, label: Text('Categorías')),
            ],
            selected: {products},
            onSelectionChanged: (value) =>
                setState(() => products = value.first),
          ),
          const SizedBox(height: 16),
          if (products) const _ProductsPanel() else const _CategoriesPanel(),
        ]),
      );
}

class _CategoriesPanel extends ConsumerWidget {
  const _CategoriesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backofficeCategoriesProvider);
    return _AsyncBody(
      state: state,
      builder: (value) => Column(children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _createCategory(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
        ),
        for (final raw in value as List)
          _CategoryTile(
            item: _map(raw),
            onChanged: () => ref.invalidate(backofficeCategoriesProvider),
          ),
        if (value.isEmpty)
          const _EmptyCard(message: 'No hay categorías activas.'),
      ]),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.item, required this.onChanged});
  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: ListTile(
          title: Text(item['name']?.toString() ?? 'Sin nombre'),
          subtitle: Text('Nivel ${item['depth'] ?? '-'}'),
          trailing: IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final name = await _textValue(
                  context, 'Editar categoría', item['name']?.toString() ?? '');
              if (name == null) return;
              await ref
                  .read(backofficeRepositoryProvider)
                  .remote
                  .updateCategory(item['id'].toString(), name);
              onChanged();
            },
          ),
        ),
      );
}

Future<void> _createCategory(BuildContext context, WidgetRef ref) async {
  final name = await _textValue(context, 'Nueva categoría', '');
  if (name == null) return;
  await ref.read(backofficeRepositoryProvider).remote.createCategory({
    'id': const Uuid().v7(),
    'name': name,
    'parentId': null,
  });
  ref.invalidate(backofficeCategoriesProvider);
}

class _ProductsPanel extends ConsumerWidget {
  const _ProductsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AsyncBody(
        state: ref.watch(backofficeProductsProvider),
        builder: (value) => Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _createProduct(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            ),
          ),
          for (final raw in value as List)
            _ProductTile(
              item: _map(raw),
              onChanged: () => ref.invalidate(backofficeProductsProvider),
            ),
          if (value.isEmpty)
            const _EmptyCard(message: 'No hay productos en el catálogo.'),
        ]),
      );
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.item, required this.onChanged});
  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: ListTile(
          title: Text(item['name']?.toString() ?? 'Sin nombre'),
          subtitle: Text('${item['unit'] ?? '-'} · ${item['status'] ?? ''}'),
          trailing: IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final name = await _textValue(
                  context, 'Editar producto', item['name']?.toString() ?? '');
              if (name == null) return;
              await ref
                  .read(backofficeRepositoryProvider)
                  .remote
                  .updateProduct(item['id'].toString(), {
                'categoryId': item['categoryId'],
                'name': name,
                'unit': item['unit'],
                'attributes': item['attributes'] ?? {},
              });
              onChanged();
            },
          ),
        ),
      );
}

Future<void> _createProduct(BuildContext context, WidgetRef ref) async {
  final name = await _textValue(context, 'Nuevo producto', '');
  if (name == null) return;
  final categories = await ref.read(backofficeCategoriesProvider.future);
  if (categories.isEmpty || !context.mounted) return;
  final categoryId = _map(categories.first)['id']?.toString();
  if (categoryId == null) return;
  await ref.read(backofficeRepositoryProvider).remote.createProduct({
    'id': const Uuid().v7(),
    'categoryId': categoryId,
    'name': name,
    'unit': 'kg',
    'attributes': <String, dynamic>{},
  });
  ref.invalidate(backofficeProductsProvider);
}

Future<String?> _textValue(
    BuildContext context, String title, String initialValue) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.pop(context, value.isEmpty ? null : value);
            },
            child: const Text('Guardar')),
      ],
    ),
  );
}

Future<String?> _textReason(BuildContext context) async {
  final c = TextEditingController();
  return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
              title: const Text('Motivo de rechazo'),
              content: TextField(controller: c, maxLength: 300),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(
                        context, c.text.trim().isEmpty ? null : c.text.trim()),
                    child: const Text('Confirmar'))
              ]));
}

class _LogisticsView extends ConsumerWidget {
  const _LogisticsView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BackofficePage(
      title: 'Centro logístico',
      child: _AsyncBody(
          state: ref.watch(backofficeLogisticsProvider),
          builder: (value) {
            final data = value as Map<String, dynamic>;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryList(
                      title: 'Transportistas',
                      values: data['carriers'] as List? ?? const []),
                  _TripsPanel(
                      values: data['trips'] as List? ?? const [],
                      carriers: data['carriers'] as List? ?? const [],
                      onChanged: () =>
                          ref.invalidate(backofficeLogisticsProvider)),
                  _IncidentsPanel(
                      values: data['incidents'] as List? ?? const [],
                      onChanged: () =>
                          ref.invalidate(backofficeLogisticsProvider)),
                  Text(
                      'Pedidos en conflicto: ${_map(data['conflicts'])['orderIds'] ?? []}')
                ]);
          }));
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.title, required this.values});
  final String title;
  final List values;
  @override
  Widget build(BuildContext context) =>
      ExpansionTile(title: Text('$title (${values.length})'), children: [
        for (final value in values.take(20))
          ListTile(
              dense: true,
              title: Text(_map(value)['id']?.toString() ??
                  _map(value)['userId']?.toString() ??
                  'Registro'),
              subtitle: Text(_map(value)['status']?.toString() ?? ''))
      ]);
}

class _TripsPanel extends StatelessWidget {
  const _TripsPanel(
      {required this.values, required this.carriers, required this.onChanged});
  final List values;
  final List carriers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: Text('Viajes activos (${values.length})'),
        children: [
          for (final raw in values)
            _TripTile(
                item: _map(raw), carriers: carriers, onChanged: onChanged),
        ],
      );
}

class _TripTile extends StatelessWidget {
  const _TripTile(
      {required this.item, required this.carriers, required this.onChanged});
  final Map<String, dynamic> item;
  final List carriers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(item['id']?.toString() ?? 'Viaje'),
        subtitle:
            Text('${item['status'] ?? ''} · versión ${item['version'] ?? '-'}'),
        trailing: Wrap(children: [
          IconButton(
            tooltip: 'Reasignar',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _reassign(context),
          ),
          IconButton(
            tooltip: 'Cancelar',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () => _cancel(context),
          ),
        ]),
      );

  Future<void> _reassign(BuildContext context) async {
    if (carriers.isEmpty) return;
    final carrierId = _map(carriers.first)['userId']?.toString();
    final id = item['id']?.toString();
    if (carrierId == null || id == null) return;
    if (!await _confirm(context, 'Reasignar viaje',
        'Se reasignará al primer transportista disponible.')) {
      return;
    }
    if (!context.mounted) return;
    await _backofficeRemote(context).reassignTrip(id, carrierId, _version);
    onChanged();
  }

  Future<void> _cancel(BuildContext context) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final reason = await _textReason(context);
    if (reason == null || !context.mounted) return;
    await _backofficeRemote(context).cancelTrip(id, _version, reason);
    onChanged();
  }

  int get _version => (item['version'] as num?)?.toInt() ?? 0;
  BackofficeRemoteDataSource _backofficeRemote(BuildContext context) =>
      ProviderScope.containerOf(context)
          .read(backofficeRepositoryProvider)
          .remote;
}

class _IncidentsPanel extends StatelessWidget {
  const _IncidentsPanel({required this.values, required this.onChanged});
  final List values;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: Text('Incidencias (${values.length})'),
        children: [
          for (final raw in values)
            ListTile(
              title: Text(_map(raw)['type']?.toString() ?? 'Incidencia'),
              subtitle: Text(_map(raw)['description']?.toString() ?? ''),
              trailing: _map(raw)['status'] == 'resolved'
                  ? const Text('Resuelta')
                  : TextButton(
                      onPressed: () async {
                        final id = _map(raw)['id']?.toString();
                        if (id == null) {
                          return;
                        }
                        if (!await _confirm(context, 'Resolver incidencia',
                            'La incidencia quedará cerrada.')) {
                          return;
                        }
                        if (!context.mounted) return;
                        await ProviderScope.containerOf(context)
                            .read(backofficeRepositoryProvider)
                            .remote
                            .resolveIncident(id);
                        onChanged();
                      },
                      child: const Text('Resolver'),
                    ),
            ),
        ],
      );
}

class _ParametersView extends ConsumerWidget {
  const _ParametersView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BackofficePage(
      title: 'Parámetros de negocio',
      child: _AsyncBody(
          state: ref.watch(backofficeParametersProvider),
          builder: (value) => Column(children: [
                for (final raw in value as List)
                  _ParameterTile(
                      item: _map(raw),
                      onChanged: () =>
                          ref.invalidate(backofficeParametersProvider))
              ])));
}

class _ParameterTile extends ConsumerWidget {
  const _ParameterTile({required this.item, required this.onChanged});
  final Map<String, dynamic> item;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
      child: ListTile(
          title: Text(item['key']?.toString() ?? ''),
          subtitle: Text(
              '${item['description'] ?? ''}\nRango: ${item['min'] ?? '-'} a ${item['max'] ?? '-'} ${item['provisional'] == true ? '· PROVISIONAL' : ''}'),
          trailing: TextButton(
              onPressed:
                  ref.watch(authProvider).valueOrNull?.user.role == 'admin'
                      ? () => _edit(context, ref)
                      : null,
              child: Text(item['value']?.toString() ?? ''))));
  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: item['value']?.toString() ?? '');
    final value = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
                title: Text('Editar ${item['key']}'),
                content: TextField(
                    controller: c, keyboardType: TextInputType.number),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, c.text.trim()),
                      child: const Text('Guardar'))
                ]));
    if (value == null || value.isEmpty || !context.mounted) return;
    if (await _confirm(
        context, 'Confirmar cambio', 'Afecta operaciones futuras.')) {
      await ref
          .read(backofficeRepositoryProvider)
          .remote
          .updateParameter(item['key'].toString(), value);
      onChanged();
    }
  }
}

class _AuditView extends ConsumerWidget {
  const _AuditView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => _BackofficePage(
      title: 'Auditoría',
      child: _AsyncBody(
          state: ref.watch(backofficeAuditProvider),
          builder: (value) => Column(children: [
                for (final raw in value as List)
                  Card(
                      child: ListTile(
                          title: Text(
                              '${_map(raw)['action'] ?? ''} · ${_map(raw)['entity'] ?? ''}'),
                          subtitle: Text(
                              '${_map(raw)['at'] ?? ''}\nID: ${_map(raw)['entityId'] ?? ''}'))),
                if (value.isEmpty)
                  const _EmptyCard(message: 'No hay eventos de auditoría.')
              ])));
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(padding: const EdgeInsets.all(20), child: Text(message)));
}
