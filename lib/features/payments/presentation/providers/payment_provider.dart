import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/payment.dart';
import '../../domain/payment_attempt_ids.dart';
import '../../domain/repository/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  throw UnimplementedError(
      'PaymentRepository requires PaymentRemoteDataSource setup.');
});

/// Ids de intento de pago; uno por sesión de la app (ver PaymentAttemptIds).
final paymentAttemptIdsProvider =
    Provider<PaymentAttemptIds>((ref) => PaymentAttemptIds());

// Los providers de pago son autoDispose: al salir de la pantalla se descarta
// el pago y con él la URL firmada del comprobante (solo vive en memoria).

/// Pago más reciente de un pedido; `null` si todavía no existe.
final orderPaymentProvider =
    FutureProvider.autoDispose.family<Payment?, String>((ref, orderId) async {
  ref.watch(authProvider);
  final result = await ref.read(paymentRepositoryProvider).getForOrder(orderId);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final paymentDetailProvider =
    FutureProvider.autoDispose.family<Payment, String>((ref, paymentId) async {
  ref.watch(authProvider);
  final result = await ref.read(paymentRepositoryProvider).getById(paymentId);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

/// Cola de revisión del personal: comprobantes por verificar y disputas.
final paymentReviewQueueProvider =
    FutureProvider.autoDispose<List<Payment>>((ref) async {
  ref.watch(authProvider);
  final result = await ref.read(paymentRepositoryProvider).reviewQueue();
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});
