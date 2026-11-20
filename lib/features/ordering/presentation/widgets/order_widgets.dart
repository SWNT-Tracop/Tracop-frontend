import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/formats.dart';
import '../../domain/entities/order.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status, this.large = false});
  final String status;
  final bool large;

  static const _labels = <String, String>{
    'draft': 'Borrador',
    'requested': 'Solicitado',
    'quoted': 'Cotización lista',
    'accepted': 'Aceptado',
    'payment_pending': 'Pago pendiente',
    'paid': 'Pagado',
    'pickup_scheduled': 'Recogida programada',
    'in_transit': 'En camino',
    'delivered': 'Entregado',
    'closed': 'Cerrado',
    'disputed': 'En revisión',
    'cancelled': 'Cancelado',
  };

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'accepted' ||
      'paid' ||
      'pickup_scheduled' ||
      'in_transit' ||
      'delivered' ||
      'closed' =>
        AppTheme.forest,
      'requested' || 'quoted' || 'payment_pending' => const Color(0xFFB45309),
      'cancelled' || 'disputed' => AppTheme.mutedText,
      _ => AppTheme.mutedText,
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(_labels[status] ?? status,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12)),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.incoming = false});
  final OrderResponse order;
  final bool incoming;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          onTap: () => context.push('/pedidos/${order.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                      'Pedido #${order.id.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                OrderStatusBadge(status: order.status),
              ]),
              const SizedBox(height: 10),
              Text(
                  incoming
                      ? 'Comprador TRACOP'
                      : (order.provider?['displayName'] as String? ??
                          AppFormats.dayMonthYear(order.createdAt)),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF334155))),
              if (!incoming)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(AppFormats.dayMonthYear(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          )),
                ),
              const SizedBox(height: 8),
              Text(AppFormats.moneyText(order.amounts.total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forest,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        ),
      );
}

class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({super.key, required this.amounts});
  final QuoteAmounts amounts;

  @override
  Widget build(BuildContext context) => Column(children: [
        _row(context, 'Subtotal', amounts.subtotal),
        _row(context, 'Flete', amounts.freight),
        _row(context, 'Comisión TRACOP', amounts.commission),
        const Divider(height: 24),
        _row(context, 'Total', amounts.total, strong: true),
        _row(context, 'Recibe el proveedor', amounts.providerNet),
      ]);

  Widget _row(BuildContext context, String label, String value,
          {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style:
                      TextStyle(fontWeight: strong ? FontWeight.w700 : null))),
          Text(AppFormats.moneyText(value),
              style: TextStyle(
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: strong ? AppTheme.forest : null)),
        ]),
      );
}
