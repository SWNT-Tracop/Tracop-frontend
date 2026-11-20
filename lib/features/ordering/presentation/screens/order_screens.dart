import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/result/result.dart';
import '../../../../features/catalog/domain/entities/lot.dart'
    hide Category, Product;
import '../../../../features/catalog/domain/lot_quantity.dart';
import '../../../../features/catalog/presentation/providers/lot_management_provider.dart'
    show catalogProductsProvider;
import '../../../../features/home/presentation/home_screen.dart';
import '../../../../shared/widgets/option_selectors.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';
import '../widgets/order_widgets.dart';

const _titleStyle = TextStyle(
  color: Color(0xFF115E26),
  fontWeight: FontWeight.w700,
  letterSpacing: 1.1,
);

class OrderRoleGate extends ConsumerWidget {
  const OrderRoleGate({super.key, required this.roles, required this.child});
  final Set<String> roles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(homeUserProvider);
    final role = user.valueOrNull?.role;
    if (role == null && user.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (role == null || !roles.contains(role)) {
      return const Center(
          child: Text('Esta sección no está disponible para tu cuenta.'));
    }
    return child;
  }
}

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final _scroll = ScrollController();
  final List<OrderResponse> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _cached = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreOnScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadMoreOnScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 160) {
      _load(more: true);
    }
  }

  Future<void> _load({bool more = false}) async {
    if (_loadingMore || (more && _cursor == null)) return;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });
    final result = await ref
        .read(orderRepositoryProvider)
        .listMyOrders(cursor: more ? _cursor : null, limit: 20);
    if (!mounted) return;
    result.map(
      ok: (value) {
        final page = value.value;
        setState(() {
          if (!more) _items.clear();
          for (final order in page.items) {
            if (!_items.any((item) => item.id == order.id)) _items.add(order);
          }
          _cursor = page.nextCursor;
          _cached = page.isFromCache;
          _loading = false;
          _loadingMore = false;
        });
      },
      err: (failure) => setState(() {
        _error = failure.error;
        _loading = false;
        _loadingMore = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => OrderRoleGate(
        roles: const {'buyer'},
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Row(children: [
                Expanded(
                    child: Text('MIS PEDIDOS',
                        style: _titleStyle.copyWith(fontSize: 20))),
                if (_cached) const _OfflineTag(),
              ]),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => context.push('/pedidos/nuevo'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo pedido'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF70C043),
                    foregroundColor: const Color(0xFF173B1E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading && _items.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator()))
              else if (_error != null && _items.isEmpty)
                _ErrorPanel(message: _errorMessage(_error!), onRetry: _load)
              else if (_items.isEmpty)
                const _EmptyOrders(
                  icon: Icons.shopping_cart_outlined,
                  title: 'No tienes pedidos aún',
                  subtitle: 'Cuando solicites una cotización, aparecerá aquí.',
                )
              else ...[
                for (final order in _items) OrderCard(order: order),
                if (_loadingMore)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator())),
              ],
            ],
          ),
        ),
      );
}

class IncomingOrdersScreen extends ConsumerStatefulWidget {
  const IncomingOrdersScreen({super.key});
  @override
  ConsumerState<IncomingOrdersScreen> createState() =>
      _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends ConsumerState<IncomingOrdersScreen> {
  final _scroll = ScrollController();
  final List<OrderResponse> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _cached = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 160) {
        _load(more: true);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loadingMore || (more && _cursor == null)) return;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });
    final result = await ref
        .read(orderRepositoryProvider)
        .listIncomingOrders(cursor: more ? _cursor : null, limit: 20);
    if (!mounted) return;
    result.map(
      ok: (value) {
        final page = value.value;
        setState(() {
          if (!more) _items.clear();
          for (final order in page.items) {
            if (!_items.any((item) => item.id == order.id)) _items.add(order);
          }
          _cursor = page.nextCursor;
          _cached = page.isFromCache;
          _loading = false;
          _loadingMore = false;
        });
      },
      err: (failure) => setState(() {
        _error = failure.error;
        _loading = false;
        _loadingMore = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => OrderRoleGate(
        roles: const {'supplier'},
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Row(children: [
                Expanded(
                    child: Text('PEDIDOS ENTRANTES',
                        style: _titleStyle.copyWith(fontSize: 20))),
                if (_cached) const _OfflineTag(),
              ]),
              const SizedBox(height: 16),
              if (_loading && _items.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator()))
              else if (_error != null && _items.isEmpty)
                _ErrorPanel(message: _errorMessage(_error!), onRetry: _load)
              else if (_items.isEmpty)
                const _EmptyOrders(
                  icon: Icons.inbox_outlined,
                  title: 'No hay pedidos entrantes',
                  subtitle: 'Los pedidos aceptados aparecerán aquí.',
                )
              else ...[
                for (final order in _items)
                  OrderCard(order: order, incoming: true),
                if (_loadingMore)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator())),
              ],
            ],
          ),
        ),
      );
}

class OrderCheckoutScreen extends ConsumerStatefulWidget {
  const OrderCheckoutScreen({super.key, this.initialLot});
  final Lot? initialLot;
  @override
  ConsumerState<OrderCheckoutScreen> createState() =>
      _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends ConsumerState<OrderCheckoutScreen> {
  final _address = TextEditingController();
  final _quantities = <String, TextEditingController>{};
  final _selectedLots = <String, Lot>{};
  DateTime? _deliveryWindow;
  bool _submitting = false;
  String? _addressError;
  String? _lineError;

  @override
  void initState() {
    super.initState();
    final lot = widget.initialLot;
    if (lot != null && !lot.isMine) {
      _selectedLots[lot.id] = lot;
      _quantities[lot.id] = TextEditingController(text: '1');
    }
  }

  @override
  void dispose() {
    _address.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickWindow() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deliveryWindow ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deliveryWindow ?? date));
    if (time != null) {
      setState(() => _deliveryWindow =
          DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  void _addLot(Lot? lot) {
    if (lot == null || _selectedLots.containsKey(lot.id)) return;
    setState(() {
      _selectedLots[lot.id] = lot;
      _quantities[lot.id] = TextEditingController(text: '1');
      _lineError = null;
    });
  }

  int get _estimatedSubtotal {
    var subtotal = 0;
    for (final entry in _selectedLots.entries) {
      final milli = parseQuantityMilli(_quantities[entry.key]?.text ?? '');
      final price = int.tryParse(entry.value.unitPrice) ?? 0;
      if (milli != null) subtotal += price * milli ~/ 1000;
    }
    return subtotal;
  }

  Future<void> _submit(bool online) async {
    if (!online || _submitting) return;
    final address = _address.text.trim();
    final addressError = address.isEmpty
        ? 'Escribe la dirección de entrega.'
        : address.length > 500
            ? 'La dirección no puede superar 500 caracteres.'
            : null;
    final invalidLine = _selectedLots.entries.any((entry) =>
        parseQuantityMilli(_quantities[entry.key]?.text ?? '') == null);
    setState(() {
      _addressError = addressError;
      _lineError = _selectedLots.isEmpty
          ? 'Agrega al menos un lote.'
          : invalidLine
              ? 'Revisa las cantidades: deben ser mayores que cero.'
              : null;
    });
    if (addressError != null || _lineError != null) return;

    setState(() => _submitting = true);
    final request = CreateOrderRequest(
      id: const Uuid().v7(),
      lines: _selectedLots.entries
          .map((entry) => OrderLineInput(
                lotId: entry.key,
                quantityMilli: parseQuantityMilli(_quantities[entry.key]!.text)!
                    .toString(),
              ))
          .toList(),
      deliveryAddress: address,
      deliveryWindow: _deliveryWindow,
    );
    final result = await ref.read(orderRepositoryProvider).createOrder(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    result.map(
      ok: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido solicitado correctamente.')));
        context.go('/pedidos/mis-pedidos');
      },
      err: (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(failure.error)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lotsAsync = ref.watch(orderLotsProvider);
    final products = ref.watch(catalogProductsProvider).valueOrNull ?? const [];
    final connectivity = ref.watch(homeConnectivityProvider).valueOrNull;
    final online = connectivity == true;
    return OrderRoleGate(
      roles: const {'buyer'},
      child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text('NUEVO PEDIDO', style: _titleStyle.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            Text('Lotes',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            lotsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No se pudieron cargar los lotes.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(orderLotsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Intentar de nuevo'),
                  ),
                  if (error is DomainFailure && error.code != 'unknown')
                    Text('Detalle: ${error.code}',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              data: (lots) {
                final options = lots
                    .where((lot) => !_selectedLots.containsKey(lot.id))
                    .map((lot) => SelectorOption<String>(
                          value: lot.id,
                          label:
                              '${products.where((product) => product.id == lot.productId).firstOrNull?.name ?? 'Lote'} · ${lot.id.substring(0, 8).toUpperCase()}',
                          subtitle:
                              '${AppFormats.moneyText(lot.unitPrice)} / ${lot.unit}',
                          icon: Icons.eco_outlined,
                        ))
                    .toList();
                return SearchableSheetSelector<String>(
                  label: 'Agregar lote',
                  options: options,
                  value: null,
                  hint: 'Selecciona un lote',
                  enabled: _selectedLots.length < 20,
                  onChanged: (id) =>
                      _addLot(lots.where((lot) => lot.id == id).firstOrNull),
                  emptyLabel: 'No hay lotes disponibles',
                );
              },
            ),
            if (_selectedLots.length >= 20)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Puedes agregar hasta 20 lotes por pedido.'),
              ),
            if (_lineError != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_lineError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 8),
            for (final entry in _selectedLots.entries)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                '${products.where((product) => product.id == entry.value.productId).firstOrNull?.name ?? 'Lote'} · ${entry.key.substring(0, 8).toUpperCase()} · ${entry.value.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                        SizedBox(
                            width: 88,
                            child: TextField(
                              key: ValueKey(entry.key),
                              controller: _quantities[entry.key],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,.]'))
                              ],
                              decoration: const InputDecoration(
                                  labelText: 'Cantidad', isDense: true),
                            )),
                        IconButton(
                            tooltip: 'Quitar lote',
                            onPressed: () => setState(() {
                                  _selectedLots.remove(entry.key);
                                  _quantities.remove(entry.key)?.dispose();
                                }),
                            icon: const Icon(Icons.close)),
                      ]))),
            const SizedBox(height: 18),
            TextField(
              controller: _address,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Dirección de entrega *',
                hintText: 'Calle, carrera, barrio y ciudad',
                errorText: _addressError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_addressError != null) setState(() => _addressError = null);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickWindow,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_deliveryWindow == null
                  ? 'Elegir ventana de entrega (opcional)'
                  : 'Entrega: ${AppFormats.dayMonthTime(_deliveryWindow!)}'),
            ),
            const SizedBox(height: 20),
            _CheckoutPricePreview(
                subtotal: _estimatedSubtotal,
                hasLines: _selectedLots.isNotEmpty),
            if (!online)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                    'Sin conexión. Conéctate para solicitar la cotización.',
                    style: TextStyle(color: Color(0xFF8D6E63))),
              ),
            const SizedBox(height: 20),
            SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                      online && !_submitting ? () => _submit(online) : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF115E26)),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Solicitar cotización'),
                )),
          ]),
    );
  }
}

class _CheckoutPricePreview extends StatelessWidget {
  const _CheckoutPricePreview({required this.subtotal, required this.hasLines});
  final int subtotal;
  final bool hasLines;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAF7),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          _previewRow(
              'Subtotal estimado', hasLines ? AppFormats.money(subtotal) : '—'),
          _previewRow('Flete y comisión', 'Se calculan al cotizar'),
          const Divider(height: 24),
          _previewRow('Total', 'Pendiente de cotización', strong: true),
        ]),
      );
  Widget _previewRow(String label, String value, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style:
                      TextStyle(fontWeight: strong ? FontWeight.w700 : null))),
          Text(value,
              style: TextStyle(
                  fontWeight: strong ? FontWeight.w700 : null,
                  fontFeatures: const [FontFeature.tabularFigures()]))
        ]),
      );
}

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _accept(OrderResponse order) async {
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('ACEPTAR COTIZACIÓN', style: _titleStyle),
              content: const Text('¿Aceptar esta cotización?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Volver')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Aceptar'))
              ],
            ));
    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(orderRepositoryProvider)
        .acceptQuote(order.id, order.version);
    if (!mounted) return;
    setState(() => _busy = false);
    result.map(
      ok: (_) {
        ref.invalidate(orderDetailProvider(order.id));
        ref.invalidate(myOrdersProvider(null));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotización aceptada.')));
      },
      err: (failure) {
        if (failure.error.code == 'version_conflict') {
          ref.invalidate(orderDetailProvider(order.id));
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage(failure.error))));
      },
    );
  }

  Future<void> _cancel(OrderResponse order) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('CANCELAR PEDIDO', style: _titleStyle),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¿Cancelar este pedido?'),
                    const SizedBox(height: 12),
                    TextField(
                        controller: reason,
                        maxLength: 200,
                        decoration: const InputDecoration(
                            labelText: 'Motivo (opcional)',
                            border: OutlineInputBorder())),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Volver')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cancelar pedido',
                      style: TextStyle(color: Color(0xFFB3261E))),
                ),
              ],
            ));
    if (confirmed != true || !mounted) {
      reason.dispose();
      return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(orderRepositoryProvider)
        .cancelOrder(order.id, order.version, reason: reason.text);
    reason.dispose();
    if (!mounted) return;
    setState(() => _busy = false);
    result.map(
      ok: (_) {
        ref.invalidate(orderDetailProvider(order.id));
        ref.invalidate(myOrdersProvider(null));
        ref.invalidate(incomingOrdersProvider(null));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Pedido cancelado.')));
      },
      err: (failure) {
        if (failure.error.code == 'version_conflict') {
          ref.invalidate(orderDetailProvider(order.id));
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage(failure.error))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderId));
    final role = ref.watch(homeUserProvider).valueOrNull?.role;
    final online = ref.watch(homeConnectivityProvider).valueOrNull == true;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPanel(
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId))),
      data: (order) {
        final isBuyer = role == 'buyer';
        final canCancel = {'requested', 'quoted', 'accepted', 'payment_pending'}
                .contains(order.status) &&
            (isBuyer || role == 'supplier');
        return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              Text('PEDIDO #${order.id.substring(0, 8).toUpperCase()}',
                  style: _titleStyle.copyWith(fontSize: 20)),
              const SizedBox(height: 14),
              Align(
                  alignment: Alignment.centerLeft,
                  child: OrderStatusBadge(status: order.status, large: true)),
              const SizedBox(height: 20),
              Text('Productos',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final line in order.lines)
                Card(
                    child: ListTile(
                  leading:
                      const Icon(Icons.eco_outlined, color: AppTheme.forest),
                  title:
                      Text('Lote ${line.lotId.substring(0, 8).toUpperCase()}'),
                  subtitle: Text(
                      '${formatQuantityMilli(line.quantityMilli)} ${line.unit} × ${AppFormats.moneyText(line.unitPrice)}'),
                  trailing: Text(AppFormats.money(
                      (int.tryParse(line.quantityMilli) ?? 0) *
                          (int.tryParse(line.unitPrice) ?? 0) ~/
                          1000)),
                )),
              const SizedBox(height: 8),
              PriceBreakdown(amounts: order.amounts),
              if (isBuyer && order.deliveryAddress != null) ...[
                const SizedBox(height: 20),
                Text('Dirección de entrega',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(order.deliveryAddress!),
                if (order.deliveryWindow != null)
                  Text(
                      'Ventana: ${AppFormats.dayMonthTime(order.deliveryWindow!)}'),
              ],
              if (order.acceptedAt != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                        'Aceptado el ${AppFormats.dayMonthTime(order.acceptedAt!)}',
                        style: const TextStyle(color: Color(0xFF334155)))),
              if (order.cancelReason != null && order.status == 'cancelled')
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        'Motivo: ${_cancelReasonLabel(order.cancelReason!)}',
                        style: const TextStyle(color: Color(0xFF334155)))),
              if (!online)
                const Padding(
                    padding: EdgeInsets.only(top: 14), child: _OfflineTag()),
              if (isBuyer && order.status == 'quoted') ...[
                const SizedBox(height: 20),
                SizedBox(
                    height: 50,
                    child: FilledButton(
                        onPressed:
                            online && !_busy ? () => _accept(order) : null,
                        child: _busy
                            ? const CircularProgressIndicator()
                            : const Text('Aceptar cotización'))),
              ],
              if (canCancel) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                    onPressed: online && !_busy ? () => _cancel(order) : null,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar pedido'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E))),
              ],
            ]);
      },
    );
  }
}

class _OfflineTag extends StatelessWidget {
  const _OfflineTag();
  @override
  Widget build(BuildContext context) => const Chip(
      avatar: Icon(Icons.cloud_off_outlined, size: 16),
      label: Text('Datos sin conexión'),
      visualDensity: VisualDensity.compact);
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(icon, size: 42, color: AppTheme.mutedText),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF334155)))
        ]),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message, textAlign: TextAlign.center)),
        OutlinedButton(
            onPressed: onRetry, child: const Text('Intentar de nuevo')),
      ]);
}

String _errorMessage(Object error) {
  final failure = error is DomainFailure ? error : null;
  if (failure == null) return 'No se pudo cargar el pedido. Intenta de nuevo.';
  return switch (failure.code) {
    'version_conflict' =>
      'El pedido cambió. Actualiza la pantalla y revisa los datos.',
    'idempotency_content_mismatch' =>
      'Ya existe un pedido con ese identificador y otros datos.',
    'lot_unavailable' ||
    'insufficient_stock' =>
      'Uno de los lotes ya no está disponible en esa cantidad.',
    'quote_expired' => 'La cotización venció. Solicita una nueva.',
    'access_denied' => 'No tienes permiso para ver o cambiar este pedido.',
    'invalid_transition' =>
      'Este pedido ya no se puede cancelar en su estado actual.',
    'offline' ||
    'network_error' =>
      'Sin conexión. Conéctate a internet e intenta de nuevo.',
    _ when failure.statusCode == 503 =>
      'TRACOP está ocupado. Espera un momento e intenta de nuevo.',
    _ => failure.message.isNotEmpty
        ? failure.message
        : 'No se pudo completar la acción.',
  };
}

String _cancelReasonLabel(String reason) => switch (reason) {
      'buyer_cancelled' => 'Cancelado por el comprador',
      'provider_cancelled' => 'Cancelado por el proveedor',
      'expired' => 'La solicitud venció',
      'reservation_expired' => 'Venció la reserva del lote',
      _ => reason,
    };
