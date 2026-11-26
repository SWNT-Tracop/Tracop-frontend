import 'package:uuid/uuid.dart';

/// Ids UUID v7 de los intentos de pago, generados una sola vez por
/// (pedido, intento). Un doble toque o un reintento de red reutiliza el mismo
/// id, así el servidor nunca crea dos pagos. Tras un pago rechazado el intento
/// cambia (la clave incluye el id rechazado) y se genera un id nuevo.
///
/// Vive en memoria: si la app se reinicia, el backend sigue siendo idempotente
/// por pedido (devuelve el pago abierto con 200).
class PaymentAttemptIds {
  PaymentAttemptIds({String Function()? generator})
      : _generate = generator ?? (() => const Uuid().v7());

  final String Function() _generate;
  final Map<String, String> _ids = {};

  static String attemptKey(String orderId, {String? afterRejectedPaymentId}) =>
      '$orderId:${afterRejectedPaymentId ?? 'first'}';

  String idFor(String orderId, {String? afterRejectedPaymentId}) =>
      _ids.putIfAbsent(
        attemptKey(orderId, afterRejectedPaymentId: afterRejectedPaymentId),
        _generate,
      );

  /// Descarta el id de un intento (p. ej. si el servidor responde
  /// `idempotency_conflict`), para generar otro en el siguiente envío.
  void reset(String orderId, {String? afterRejectedPaymentId}) => _ids.remove(
      attemptKey(orderId, afterRejectedPaymentId: afterRejectedPaymentId));
}
